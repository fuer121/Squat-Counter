import SwiftUI

/// Root coordinator for the watch workout flow. Owns the session view model
/// and the shared "end workout" confirmation alert, then routes to a focused
/// screen per `WorkoutState`. Each state's UI lives in its own file
/// (`WorkoutConfigScreen`, `WorkoutCountdownScreen`, etc.).
struct WorkoutRootView: View {
    @StateObject private var viewModel: WorkoutSessionViewModel
    @State private var isEndWorkoutAlertPresented = false

    init(healthManager: any WorkoutHealthManaging = NoopWorkoutHealthManager()) {
        _viewModel = StateObject(
            wrappedValue: WorkoutSessionViewModel(
                healthManager: healthManager,
                hapticManager: HapticManager(performer: WatchHapticPerformer()),
                detectionManager: SquatDetectionManager(
                    sampleProvider: CoreMotionSquatSampleProvider()
                ),
                detectionMode: .live
            )
        )
    }

    var body: some View {
        routedContent
            .alert("结束本次训练？", isPresented: $isEndWorkoutAlertPresented) {
                Button("继续训练", role: .cancel) {}
                Button("结束训练", role: .destructive) {
                    viewModel.confirmEndWorkout()
                }
            } message: {
                Text("当前进度将被丢弃")
            }
    }

    @ViewBuilder
    private var routedContent: some View {
        switch viewModel.state {
        case .idle:
            WorkoutConfigScreen(viewModel: viewModel)
        case .countdown:
            WorkoutCountdownScreen(viewModel: viewModel)
        case .training:
            WorkoutTrainingScreen(viewModel: viewModel, isPaused: false, onRequestEnd: requestEnd)
        case .resting:
            WorkoutRestScreen(viewModel: viewModel, isPaused: false, onRequestEnd: requestEnd)
        case .paused:
            pausedContent
        case .completed:
            WorkoutCompletedScreen(viewModel: viewModel)
        }
    }

    /// While paused, branch on the resume target so the right screen (training
    /// or rest) shows its paused variant. A nil target falls back to config.
    @ViewBuilder
    private var pausedContent: some View {
        switch viewModel.pauseContext?.resumeTarget {
        case .resting:
            WorkoutRestScreen(viewModel: viewModel, isPaused: true, onRequestEnd: requestEnd)
        case .training:
            WorkoutTrainingScreen(viewModel: viewModel, isPaused: true, onRequestEnd: requestEnd)
        default:
            WorkoutConfigScreen(viewModel: viewModel)
        }
    }

    private func requestEnd() {
        isEndWorkoutAlertPresented = true
    }
}

#Preview {
    WorkoutRootView()
}
