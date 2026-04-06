import SwiftUI

struct PhoneCompanionHomeView: View {
    @ObservedObject var viewModel: PhoneCompanionViewModel

    var body: some View {
        NavigationStack {
            List {
                companionOverviewSection
                defaultConfigSection
                rolloutSection
            }
            .navigationTitle("Squat Counter")
        }
    }

    private var companionOverviewSection: some View {
        Section("Companion") {
            LabeledContent("形态", value: "iPhone + Watch")
            LabeledContent("训练主端", value: "Apple Watch")
            LabeledContent("首发市场", value: "中国区 / 中文 / 免费")
        }
    }

    private var defaultConfigSection: some View {
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
            ), in: WorkoutConfig.restRange)
        }
    }

    private var rolloutSection: some View {
        Section("当前阶段") {
            Text("第二阶段：工程与架构设计")
            Text("当前已落地工程骨架、共享模型和最小 companion 入口。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PhoneCompanionHomeView(viewModel: PhoneCompanionViewModel())
}
