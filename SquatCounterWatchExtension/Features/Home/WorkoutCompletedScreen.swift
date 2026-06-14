import SwiftUI

/// Terminal "训练完成" screen with restart and return-home actions.
struct WorkoutCompletedScreen: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text("训练完成")
                .font(.headline)

            Text("完成 \(viewModel.progress.currentSet) 组")
                .foregroundStyle(.secondary)

            Text("\(viewModel.progress.totalCompletedReps) 次")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Button("再来一次", action: viewModel.restartWorkout)
                .buttonStyle(.borderedProminent)

            HealthStatusBanner(message: viewModel.healthStatusMessage)

            Button("返回首页", action: viewModel.returnToHome)
        }
        .padding()
    }
}
