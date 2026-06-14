import SwiftUI

/// Rest state between sets, and the paused-from-rest variant. Shows the rest
/// countdown plus a "提前开始" skip, mirroring the original behavior.
struct WorkoutRestScreen: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel

    let isPaused: Bool
    let onRequestEnd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(isPaused ? "休息已暂停" : "本组完成")
                .font(.headline)

            Text(subtitle)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("\(viewModel.progress.remainingRestSeconds)s")
                .font(.system(size: 26, weight: .bold, design: .rounded))

            Button(isPaused ? "继续休息" : "提前开始", action: primaryAction)
                .buttonStyle(.borderedProminent)

            HStack {
                if !isPaused {
                    Button("暂停", action: viewModel.pauseWorkout)
                }

                Button("结束", role: .destructive, action: onRequestEnd)
            }

            HealthStatusBanner(message: viewModel.healthStatusMessage)
        }
        .padding()
    }

    private var subtitle: String {
        isPaused
            ? "继续后返回休息态"
            : "即将开始第 \(viewModel.progress.currentSet) / \(viewModel.config.totalSets) 组"
    }

    private func primaryAction() {
        if isPaused {
            viewModel.resumeWorkout()
        } else {
            viewModel.completeRest()
        }
    }
}
