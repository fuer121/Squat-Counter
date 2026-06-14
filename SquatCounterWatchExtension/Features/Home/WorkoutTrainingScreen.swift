import SwiftUI

/// Training state (and the paused-from-training variant). Reps are counted
/// automatically by the live detector; `+1 / -1` exist only for manual
/// correction, per the PRD.
struct WorkoutTrainingScreen: View {
    @ObservedObject var viewModel: WorkoutSessionViewModel

    /// When true the session is paused with training as the resume target;
    /// the screen shows a "继续训练" action instead of pause.
    let isPaused: Bool
    let onRequestEnd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(isPaused ? "已暂停" : "训练中")
                .font(.headline)

            Text("第 \(viewModel.progress.currentSet) / \(viewModel.config.totalSets) 组")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(viewModel.progress.currentRep) / \(viewModel.config.repsPerSet)")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(hint)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if isPaused {
                Button("继续训练", action: viewModel.resumeWorkout)
                    .buttonStyle(.borderedProminent)
            } else {
                HStack {
                    Button("-1", action: viewModel.decrementRep)
                    Button("+1", action: viewModel.incrementRep)
                }
            }

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

    private var hint: String {
        isPaused
            ? "保持当前训练进度，恢复后继续。"
            : "自动识别深蹲并计数，+1 / -1 仅用于手动纠错。"
    }
}
