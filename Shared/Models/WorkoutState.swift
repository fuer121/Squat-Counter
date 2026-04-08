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
    private static let defaultTempoCueInterval: TimeInterval = 2.0

    @Published private(set) var state: WorkoutState = .idle
    @Published private(set) var progress: WorkoutProgress = .empty
    @Published private(set) var pauseContext: PauseContext?
    @Published private(set) var countdownRemainingSeconds: Int = 0
    @Published var config: WorkoutConfig

    private let timerManager: any TimerManaging
    private let hapticManager: any HapticManaging
    private let detectionManager: any SquatDetectionManaging
    private let detectionMode: SquatDetectionMode
    private let tempoCueInterval: TimeInterval

    init(
        config: WorkoutConfig = WorkoutConfig(),
        timerManager: any TimerManaging = TimerManager(),
        hapticManager: any HapticManaging = HapticManager(),
        detectionManager: any SquatDetectionManaging = SquatDetectionManager(),
        detectionMode: SquatDetectionMode = .simulation,
        tempoCueInterval: TimeInterval = WorkoutSessionViewModel.defaultTempoCueInterval
    ) {
        self.config = config
        self.timerManager = timerManager
        self.hapticManager = hapticManager
        self.detectionManager = detectionManager
        self.detectionMode = detectionMode
        self.tempoCueInterval = tempoCueInterval
    }

    func startWorkout() {
        detectionManager.stop()
        progress = .empty
        pauseContext = nil
        countdownRemainingSeconds = config.countdownSeconds
        state = .countdown
        startTimer(.countdown(durationSeconds: config.countdownSeconds))
    }

    func cancelCountdown() {
        guard state == .countdown else { return }
        returnToHome()
    }

    func simulateRepDetection() {
        guard state == .training else { return }
        detectionManager.simulateRep()
    }

    func incrementRep() {
        applyRepIncrement()
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

        if state == .training {
            detectionManager.pause()
        }

        timerManager.pause()
        state = .paused
    }

    func resumeWorkout() {
        guard state == .paused, let resumeTarget = pauseContext?.resumeTarget else { return }
        pauseContext = nil
        state = resumeTarget

        if resumeTarget == .training {
            detectionManager.resume()
        }

        timerManager.resume()
    }

    func completeRest() {
        guard state == .resting else { return }
        timerManager.cancel()
        progress.remainingRestSeconds = 0
        enterTrainingState(triggeredBy: .nextSetStarted)
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
        detectionManager.stop()
        timerManager.cancel()
        progress = .empty
        pauseContext = nil
        countdownRemainingSeconds = 0
        state = .idle
    }

    private func applyRepIncrement() {
        guard state == .training else { return }
        guard progress.currentRep < config.repsPerSet else { return }

        progress.currentRep += 1
        progress.totalCompletedReps += 1

        guard progress.currentRep == config.repsPerSet else {
            hapticManager.play(.repCompleted)
            return
        }

        completeCurrentSet()
    }

    private func completeCurrentSet() {
        detectionManager.stop()

        if progress.currentSet >= config.totalSets {
            timerManager.cancel()
            progress.remainingRestSeconds = 0
            state = .completed
            hapticManager.playHighestPriority(among: [.workoutCompleted, .setCompleted, .repCompleted])
            return
        }

        progress.currentSet += 1
        progress.currentRep = 0
        progress.remainingRestSeconds = config.restSeconds
        state = .resting
        startTimer(.rest(durationSeconds: config.restSeconds))
        hapticManager.playHighestPriority(among: [.setCompleted, .repCompleted])
    }

    private func startTimer(_ context: TrainingTimerContext) {
        timerManager.start(context) { [weak self] event in
            self?.handleTimerEvent(event)
        }
    }

    private func startDetection() {
        detectionManager.start(mode: detectionMode) { [weak self] event in
            self?.handleDetectionEvent(event)
        }
    }

    private func handleTimerEvent(_ event: TrainingTimerEvent) {
        switch event {
        case .countdownTick(let remainingSeconds):
            guard state == .countdown else { return }
            countdownRemainingSeconds = remainingSeconds
            hapticManager.play(.countdownTick(remainingSeconds: remainingSeconds))
        case .countdownCompleted:
            guard state == .countdown else { return }
            countdownRemainingSeconds = 0
            enterTrainingState(triggeredBy: .countdownCompleted)
        case .restTick(let remainingSeconds):
            guard state == .resting else { return }
            progress.remainingRestSeconds = remainingSeconds
        case .restCompleted:
            guard state == .resting else { return }
            progress.remainingRestSeconds = 0
            enterTrainingState(triggeredBy: .nextSetStarted)
        case .tempoCue:
            guard state == .training else { return }
            hapticManager.playHighestPriority(among: [.tempoCue])
        }
    }

    private func handleDetectionEvent(_ event: SquatDetectionEvent) {
        switch event {
        case .repDetected:
            applyRepIncrement()
        case .motionStateChanged:
            break
        }
    }

    private func enterTrainingState(triggeredBy hapticEvent: TrainingHapticEvent) {
        countdownRemainingSeconds = 0
        progress.remainingRestSeconds = 0
        state = .training
        startDetection()

        if config.tempoCueEnabled {
            startTimer(.tempo(interval: tempoCueInterval))
        } else {
            timerManager.cancel()
        }

        hapticManager.playHighestPriority(among: [hapticEvent])
    }
}
