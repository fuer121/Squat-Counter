import Foundation
import SwiftUI

enum PhoneCompanionRoute: String, CaseIterable, Identifiable {
    case onboarding
    case configuration
    case help

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onboarding:
            "首次启动引导"
        case .configuration:
            "默认参数"
        case .help:
            "帮助与支持"
        }
    }

    var subtitle: String {
        switch self {
        case .onboarding:
            "了解 iPhone + Watch 的使用路径和权限原因"
        case .configuration:
            "管理每组次数、组数和休息时间"
        case .help:
            "查看 FAQ、支持说明和轻量基础信息"
        }
    }

    var systemImage: String {
        switch self {
        case .onboarding:
            "figure.walk"
        case .configuration:
            "slider.horizontal.3"
        case .help:
            "questionmark.circle"
        }
    }
}

struct PhoneCompanionSupportItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String

    init(id: String, title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

struct PhoneCompanionInfoItem: Identifiable, Equatable {
    let id: String
    let title: String
    let value: String

    init(id: String, title: String, value: String) {
        self.id = id
        self.title = title
        self.value = value
    }
}

@MainActor
final class PhoneCompanionViewModel: ObservableObject {
    private enum Keys {
        static let onboardingCompleted = "phoneCompanion.onboardingCompleted"
    }

    @Published private(set) var config: WorkoutConfig
    @Published private(set) var shouldPresentOnboarding: Bool
    @Published private(set) var saveStatusMessage: String

    let routes: [PhoneCompanionRoute]
    let supportItems: [PhoneCompanionSupportItem]
    let infoItems: [PhoneCompanionInfoItem]

    private let store: WorkoutConfigStoring
    private let defaults: UserDefaults

    init(
        store: WorkoutConfigStoring = UserDefaultsWorkoutConfigStore(),
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) {
        self.store = store
        self.defaults = defaults
        self.config = store.loadConfig()
        self.shouldPresentOnboarding = !defaults.bool(forKey: Keys.onboardingCompleted)
        self.saveStatusMessage = "默认参数仅保存在本机 iPhone，不代表已同步到 Watch。"
        self.routes = PhoneCompanionRoute.allCases
        self.supportItems = [
            PhoneCompanionSupportItem(
                id: "faq",
                title: "FAQ",
                detail: "说明 companion 形态、Watch 为训练主端，以及默认参数如何影响下一次训练准备。"
            ),
            PhoneCompanionSupportItem(
                id: "support",
                title: "支持说明",
                detail: "支持邮箱和正式反馈入口待补齐；当前版本先保留产品口径与说明入口。"
            ),
            PhoneCompanionSupportItem(
                id: "privacy",
                title: "隐私说明",
                detail: "当前 companion 只管理本机默认参数，不在 6.6 阶段承接云端数据或训练结果回传。"
            )
        ]
        self.infoItems = [
            PhoneCompanionInfoItem(id: "shape", title: "产品形态", value: "iPhone + Watch"),
            PhoneCompanionInfoItem(id: "source", title: "训练主端", value: "Apple Watch"),
            PhoneCompanionInfoItem(id: "scope", title: "1.0 范围", value: "无历史页 / 无实时训练控制"),
            PhoneCompanionInfoItem(id: "version", title: "当前版本", value: Self.makeVersionText(bundle: bundle))
        ]
    }

    var configSummary: String {
        "每组 \(config.repsPerSet) 次 · 共 \(config.totalSets) 组 · 休息 \(config.restSeconds) 秒"
    }

    func presentOnboarding() {
        shouldPresentOnboarding = true
    }

    func completeOnboarding() {
        defaults.set(true, forKey: Keys.onboardingCompleted)
        shouldPresentOnboarding = false
    }

    func updateReps(_ reps: Int) {
        config.repsPerSet = WorkoutConfig.repsRange.clamp(reps)
        persist()
    }

    func updateSets(_ sets: Int) {
        config.totalSets = WorkoutConfig.setsRange.clamp(sets)
        persist()
    }

    func updateRest(_ seconds: Int) {
        config.restSeconds = WorkoutConfig.restRange.clamp(seconds)
        persist()
    }

    private func persist() {
        store.saveConfig(config)
        saveStatusMessage = "默认参数已保存到本机 iPhone，不代表已同步到 Watch。"
    }

    private static func makeVersionText(bundle: Bundle) -> String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发构建"
        let build = bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String

        guard let build, !build.isEmpty else {
            return version
        }

        return "\(version) (\(build))"
    }
}

private extension ClosedRange where Bound == Int {
    func clamp(_ value: Int) -> Int {
        Swift.min(Swift.max(lowerBound, value), upperBound)
    }
}
