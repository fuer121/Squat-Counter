import SwiftUI

struct PhoneCompanionHomeView: View {
    @ObservedObject var viewModel: PhoneCompanionViewModel

    var body: some View {
        NavigationStack {
            List {
                overviewSection
                defaultConfigSummarySection
                latestSummarySection
                navigationSection
                companionBoundarySection
            }
            .navigationTitle("Squat Counter")
            .fullScreenCover(isPresented: onboardingPresentationBinding) {
                NavigationStack {
                    PhoneCompanionOnboardingView(
                        finishButtonTitle: "开始使用",
                        onFinish: viewModel.completeOnboarding
                    )
                }
            }
        }
    }

    private var onboardingPresentationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.shouldPresentOnboarding },
            set: { isPresented in
                if !isPresented {
                    viewModel.completeOnboarding()
                }
            }
        )
    }

    private var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("iPhone Companion")
                    .font(.headline)
                Text("用单首页承接引导、默认参数和帮助入口；训练主流程仍运行在 Apple Watch。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var defaultConfigSummarySection: some View {
        Section("默认参数摘要") {
            Text(viewModel.configSummary)
                .font(.body.weight(.medium))

            LabeledContent("形态", value: "iPhone + Watch")
            LabeledContent("训练主端", value: "Apple Watch")
            Text(viewModel.saveStatusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var navigationSection: some View {
        Section("页面入口") {
            ForEach(viewModel.routes) { route in
                NavigationLink {
                    destinationView(for: route)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(route.title)
                            Text(route.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: route.systemImage)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var latestSummarySection: some View {
        if let headline = viewModel.latestSummaryHeadline,
           let detail = viewModel.latestSummaryDetail,
           let timestamp = viewModel.latestSummaryTimestamp {
            Section("最近一次训练摘要") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(headline)
                        .font(.body.weight(.medium))
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(timestamp)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var companionBoundarySection: some View {
        Section("当前边界") {
            Text("不提供历史页、训练结果页、实时训练控制或实时状态镜像。")
            Text("默认参数会同步到 Watch 的下一次训练默认值；首页只承接最近一次训练摘要，不扩展为历史页。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func destinationView(for route: PhoneCompanionRoute) -> some View {
        switch route {
        case .onboarding:
            PhoneCompanionOnboardingView(
                finishButtonTitle: "完成",
                onFinish: viewModel.completeOnboarding
            )
        case .configuration:
            PhoneCompanionConfigView(viewModel: viewModel)
        case .help:
            PhoneCompanionHelpView(viewModel: viewModel)
        }
    }
}

#Preview {
    PhoneCompanionHomeView(viewModel: PhoneCompanionViewModel())
}

private struct PhoneCompanionOnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    let finishButtonTitle: String
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("开始前先确认 companion 边界")
                        .font(.title2.weight(.bold))
                    Text("iPhone 负责引导、默认参数和帮助入口；训练主流程、计数和会话真相仍在 Apple Watch。")
                        .foregroundStyle(.secondary)
                }

                onboardingCard(
                    title: "1. 训练路径",
                    detail: "在 iPhone 端了解使用方式，真正开始训练时切到 Apple Watch 完成倒计时、计数和休息闭环。"
                )
                onboardingCard(
                    title: "2. 默认参数",
                    detail: "每组次数、组数和休息时间会同步到 Watch 的下一次训练默认值；当前不提供实时训练控制。"
                )
                onboardingCard(
                    title: "3. 帮助与支持",
                    detail: "FAQ、支持说明和轻量基础信息统一收在帮助与支持页，不扩展为复杂设置中心。"
                )

                Button {
                    onFinish()
                    dismiss()
                } label: {
                    Text(finishButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("首次启动引导")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
    }

    private func onboardingCard(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PhoneCompanionConfigView: View {
    @ObservedObject var viewModel: PhoneCompanionViewModel

    var body: some View {
        Form {
            Section("默认训练参数") {
                Stepper("每组次数 \(viewModel.config.repsPerSet)", value: Binding(
                    get: { viewModel.config.repsPerSet },
                    set: { viewModel.updateReps($0) }
                ), in: WorkoutConfig.repsRange)

                Stepper("组数 \(viewModel.config.totalSets)", value: Binding(
                    get: { viewModel.config.totalSets },
                    set: { viewModel.updateSets($0) }
                ), in: WorkoutConfig.setsRange)

                Stepper("休息 \(viewModel.config.restSeconds) 秒", value: Binding(
                    get: { viewModel.config.restSeconds },
                    set: { viewModel.updateRest($0) }
                ), in: WorkoutConfig.restRange, step: 5)
            }

            Section("本地保存状态") {
                Text(viewModel.saveStatusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("当前页面会同步默认参数到 Watch 的下一次训练默认值，但不提供实时训练控制。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("默认参数")
    }
}

private struct PhoneCompanionHelpView: View {
    @ObservedObject var viewModel: PhoneCompanionViewModel

    var body: some View {
        List {
            Section("帮助与支持") {
                ForEach(viewModel.supportItems) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("轻量基础信息") {
                ForEach(viewModel.infoItems) { item in
                    LabeledContent(item.title, value: item.value)
                }
            }
        }
        .navigationTitle("帮助与支持")
    }
}
