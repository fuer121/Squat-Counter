import Combine
import Foundation

enum WorkoutState: String, Codable, CaseIterable, Sendable {
    case idle
    case countdown
    case training
    case resting
    case paused
    case completed
}

final class WorkoutSessionViewModel: ObservableObject {
    @Published private(set) var state: WorkoutState = .idle
    @Published private(set) var progress: WorkoutProgress = .empty
    @Published private(set) var pauseContext: PauseContext?
    @Published var config: WorkoutConfig

    init(config: WorkoutConfig = WorkoutConfig()) {
        self.config = config
    }

    func startWorkout() {
        progress = .empty
        pauseContext = nil
        state = .countdown
    }

    func cancelCountdown() {
        guard state == .countdown else { return }
        returnToHome()
    }

    func completeCountdown() {
        guard state == .countdown else { return }
        state = .training
    }

    func incrementRep() {
        guard state == .training else { return }
        guard progress.currentRep < config.repsPerSet else { return }

        progress.currentRep += 1
        progress.totalCompletedReps += 1

        guard progress.currentRep == config.repsPerSet else { return }
        completeCurrentSet()
    }

    func decrementRep() {
        guard state == .training else { return }
        guard progress.currentRep > 0 else { return }

        progress.currentRep -= 1
        progress.totalCompletedReps -= 1
    }

    func pauseWorkout() {
        guard state == .training || state == .resting else { return }
        pauseContext = PauseContext(resumeTarget: state)
        state = .paused
    }

    func resumeWorkout() {
        guard state == .paused, let resumeTarget = pauseContext?.resumeTarget else { return }
        pauseContext = nil
        state = resumeTarget
    }

    func completeRest() {
        guard state == .resting else { return }
        progress.remainingRestSeconds = 0
        state = .training
    }

    func confirmEndWorkout() {
        guard state == .training || state == .resting || state == .paused else { return }
        returnToHome()
    }

    func restartWorkout() {
        guard state == .completed else { return }
        startWorkout()
    }

    func returnToHome() {
        progress = .empty
        pauseContext = nil
        state = .idle
    }

    private func completeCurrentSet() {
        if progress.currentSet >= config.totalSets {
            progress.remainingRestSeconds = 0
            state = .completed
            return
        }

        progress.currentSet += 1
        progress.currentRep = 0
        progress.remainingRestSeconds = config.restSeconds
        state = .resting
    }
}
