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

    private let configStore: WorkoutConfigStoring
    private let syncCoordinator: any WatchConnectivitySyncing
    private let notificationCenter: NotificationCenter
    private let now: () -> Date
    private let timerManager: any TimerManaging
    private let hapticManager: any HapticManaging
    private let detectionManager: any SquatDetectionManaging
    private let detectionMode: SquatDetectionMode
    private let tempoCueInterval: TimeInterval
    private var lastConfigUpdatedAt: Date?
    private var pendingConfig: (config: WorkoutConfig, updatedAt: Date)?
    private var sessionStartedAt: Date?
    private var cancellables: Set<AnyCancellable> = []

    init(
        config: WorkoutConfig? = nil,
        configStore: WorkoutConfigStoring = UserDefaultsWorkoutConfigStore(),
        syncCoordinator: any WatchConnectivitySyncing = WatchConnectivitySyncCoordinator.shared,
        notificationCenter: NotificationCenter = .default,
        now: @escaping () -> Date = Date.init,
        timerManager: any TimerManaging = TimerManager(),
        hapticManager: any HapticManaging = HapticManager(),
        detectionManager: any SquatDetectionManaging = SquatDetectionManager(),
        detectionMode: SquatDetectionMode = .simulation,
        tempoCueInterval: TimeInterval = WorkoutSessionViewModel.defaultTempoCueInterval
    ) {
        self.configStore = configStore
        self.syncCoordinator = syncCoordinator
        self.notificationCenter = notificationCenter
        self.now = now
        self.config = config ?? configStore.loadConfig()
        self.timerManager = timerManager
        self.hapticManager = hapticManager
        self.detectionManager = detectionManager
        self.detectionMode = detectionMode
        self.tempoCueInterval = tempoCueInterval
        observeSyncPayloads()
    }

    func startWorkout() {
        applyPendingConfigIfNeeded()
        detectionManager.stop()
        progress = .empty
        pauseContext = nil
        countdownRemainingSeconds = config.countdownSeconds
        sessionStartedAt = now()
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
        applyPendingConfigIfNeeded()
        startWorkout()
    }

    func returnToHome() {
        detectionManager.stop()
        timerManager.cancel()
        progress = .empty
        pauseContext = nil
        countdownRemainingSeconds = 0
        sessionStartedAt = nil
        state = .idle
        applyPendingConfigIfNeeded()
    }

    func updateReps(_ reps: Int) {
        guard state == .idle || state == .completed else { return }
        applyLocalConfigChange(
            WorkoutConfig(
                repsPerSet: reps,
                totalSets: config.totalSets,
                restSeconds: config.restSeconds,
                countdownSeconds: config.countdownSeconds,
                tempoCueEnabled: config.tempoCueEnabled
            )
        )
    }

    func updateSets(_ sets: Int) {
        guard state == .idle || state == .completed else { return }
        applyLocalConfigChange(
            WorkoutConfig(
                repsPerSet: config.repsPerSet,
                totalSets: sets,
                restSeconds: config.restSeconds,
                countdownSeconds: config.countdownSeconds,
                tempoCueEnabled: config.tempoCueEnabled
            )
        )
    }

    func updateRest(_ seconds: Int) {
        guard state == .idle || state == .completed else { return }
        applyLocalConfigChange(
            WorkoutConfig(
                repsPerSet: config.repsPerSet,
                totalSets: config.totalSets,
                restSeconds: seconds,
                countdownSeconds: config.countdownSeconds,
                tempoCueEnabled: config.tempoCueEnabled
            )
        )
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
            sendLatestWorkoutSummary()
            applyPendingConfigIfNeeded()
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

    private func observeSyncPayloads() {
        notificationCenter.publisher(for: SyncPayloadNotification.didReceive)
            .compactMap(SyncPayloadNotification.payload(from:))
            .receive(on: RunLoop.main)
            .sink { [weak self] payload in
                self?.handleIncomingSyncPayload(payload)
            }
            .store(in: &cancellables)
    }

    private func handleIncomingSyncPayload(_ payload: SyncPayload) {
        guard payload.kind == .config, let incomingConfig = payload.config else {
            return
        }

        if let lastConfigUpdatedAt, payload.updatedAt < lastConfigUpdatedAt {
            return
        }

        lastConfigUpdatedAt = payload.updatedAt
        configStore.saveConfig(incomingConfig)

        if state == .idle || state == .completed {
            config = incomingConfig
            pendingConfig = nil
        } else {
            pendingConfig = (incomingConfig, payload.updatedAt)
        }
    }

    private func applyLocalConfigChange(_ updatedConfig: WorkoutConfig) {
        config = updatedConfig
        configStore.saveConfig(updatedConfig)
        lastConfigUpdatedAt = now()
    }

    private func applyPendingConfigIfNeeded() {
        guard let pendingConfig else {
            return
        }

        guard state == .idle || state == .completed else {
            return
        }

        config = pendingConfig.config
        self.pendingConfig = nil
    }

    private func sendLatestWorkoutSummary() {
        let completedAt = now()
        let startedAt = sessionStartedAt ?? completedAt
        let durationSeconds = max(Int(completedAt.timeIntervalSince(startedAt)), 0)
        let summary = WorkoutSummary(
            completedAt: completedAt,
            totalSets: progress.currentSet,
            totalReps: progress.totalCompletedReps,
            durationSeconds: durationSeconds
        )

        Task {
            try? await syncCoordinator.send(payload: .workoutSummary(summary, updatedAt: completedAt))
        }
    }
}
