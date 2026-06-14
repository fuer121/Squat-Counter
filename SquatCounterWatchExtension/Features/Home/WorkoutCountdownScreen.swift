import SwiftUI

/// Countdown state: a fixed pre-workout countdown that auto-advances to training.
struct WorkoutCountdownScreen: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text("准备开始")
                .font(.headline)

            Text("\(max(viewModel.countdownRemainingSeconds, 0))")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text("倒计时结束后自动进入训练态。")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HealthStatusBanner(message: viewModel.healthStatusMessage)

            Button("取消", action: viewModel.cancelCountdown)
        }
        .padding()
    }
}
