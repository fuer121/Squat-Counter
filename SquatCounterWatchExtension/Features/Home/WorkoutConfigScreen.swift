import SwiftUI

/// Idle state: configure reps/sets/rest and start a workout.
struct WorkoutConfigScreen: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Squat Counter")
                    .font(.headline)

                Text("开始一轮最小训练闭环")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HealthStatusBanner(message: viewModel.healthStatusMessage)

                Stepper(value: repsBinding, in: WorkoutConfig.repsRange) {
                    WorkoutSettingLabel(title: "每组次数", value: "\(viewModel.config.repsPerSet)")
                }

                Stepper(value: setsBinding, in: WorkoutConfig.setsRange) {
                    WorkoutSettingLabel(title: "总组数", value: "\(viewModel.config.totalSets)")
                }

                Stepper(value: restBinding, in: WorkoutConfig.restRange, step: 5) {
                    WorkoutSettingLabel(title: "休息时间", value: "\(viewModel.config.restSeconds) 秒")
                }

                Button("Start", action: viewModel.startWorkout)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private var repsBinding: Binding<Int> {
        Binding(
            get: { viewModel.config.repsPerSet },
            set: { viewModel.updateReps($0) }
        )
    }

    private var setsBinding: Binding<Int> {
        Binding(
            get: { viewModel.config.totalSets },
            set: { viewModel.updateSets($0) }
        )
    }

    private var restBinding: Binding<Int> {
        Binding(
            get: { viewModel.config.restSeconds },
            set: { viewModel.updateRest($0) }
        )
    }
}
