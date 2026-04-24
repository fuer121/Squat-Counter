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

enum WorkoutHealthAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case sharingAuthorized
    case sharingDenied
    case unavailable
}

enum WorkoutHealthSessionStartResult: Equatable, Sendable {
    case started
    case skipped(WorkoutHealthAuthorizationStatus)
    case failed
}

enum WorkoutHealthSaveResult: Equatable, Sendable {
    case saved
    case skipped(WorkoutHealthAuthorizationStatus)
    case failed
}

protocol WorkoutHealthManaging {
    func prepareForWorkout(at startDate: Date) async -> WorkoutHealthSessionStartResult
    func pauseWorkout() async
    func resumeWorkout() async
    func finishWorkout(summary: WorkoutSummary, endDate: Date) async -> WorkoutHealthSaveResult
    func discardWorkout() async
}

struct NoopWorkoutHealthManager: WorkoutHealthManaging {
    func prepareForWorkout(at startDate: Date) async -> WorkoutHealthSessionStartResult {
        .skipped(.unavailable)
    }

    func pauseWorkout() async {}

    func resumeWorkout() async {}

    func finishWorkout(summary: WorkoutSummary, endDate: Date) async -> WorkoutHealthSaveResult {
        .skipped(.unavailable)
    }

    func discardWorkout() async {}
}

final class WorkoutSessionViewModel: ObservableObject {
    private static let defaultTempoCueInterval: TimeInterval = 2.0

    @Published private(set) var state: WorkoutState = .idle
    @Published private(set) var progress: WorkoutProgress = .empty
    @Published private(set) var pauseContext: PauseContext?
    @Published private(set) var countdownRemainingSeconds: Int = 0
    @Published private(set) var healthAuthorizationStatus: WorkoutHealthAuthorizationStatus = .notDetermined
    @Published private(set) var healthStatusMessage: String?
    @Published private(set) var detectionStatusMessage: String?
    @Published private(set) var liveObservationMessage: String?
    @Published private(set) var isCalibrationInProgress = false
    @Published var config: WorkoutConfig

    private let configStore: WorkoutConfigStoring
    private let calibrationStore: any SquatCalibrationStoring
    private let syncCoordinator: any WatchConnectivitySyncing
    private let healthManager: any WorkoutHealthManaging
    private let notificationCenter: NotificationCenter
    private let now: () -> Date
    private let timerManager: any TimerManaging
    private let hapticManager: any HapticManaging
    private let detectionManager: any SquatDetectionManaging
    private let motionSampler: any SquatMotionSampling
    private let detectionMode: SquatDetectionMode
    private let internalDebugEnabled: Bool
    private let tempoCueInterval: TimeInterval
    private var lastConfigUpdatedAt: Date?
    private var pendingConfig: (config: WorkoutConfig, updatedAt: Date)?
    private var sessionStartedAt: Date?
    private var hasPreparedHealthWorkout = false
    private var calibrationProfile: SquatCalibrationProfile?
    private var motionSamplingAvailable: Bool?
    private var hasReceivedDeviceMotion = false
    private var lastDeviceMotionTimestamp: TimeInterval?
    private var lastCalibrationDepthAngle: Double?
    private var lastCalibrationPitchDelta: Double?
    private var lastCalibrationRepsCompleted: Int?
    private var lastCalibrationRepsTarget: Int?
    private var lastGeneratedFullDepthAngle: Double?
    private var lastGeneratedFullDepthPitchDelta: Double?
    private var lastLiveNormalizedDepth: Double?
    private var lastLiveWristRaiseMagnitude: Double?
    private var lastLiveStandingStable: Bool?
    private var lastObservedMotionState: SquatMotionState = .standing
    private var lastNoRepReason: SquatNoRepReason?
    private var cancellables: Set<AnyCancellable> = []

    var showsInternalDebugControls: Bool {
        internalDebugEnabled
    }

    init(
        config: WorkoutConfig? = nil,
        configStore: WorkoutConfigStoring = UserDefaultsWorkoutConfigStore(),
        calibrationStore: any SquatCalibrationStoring = UserDefaultsSquatCalibrationStore(),
        syncCoordinator: any WatchConnectivitySyncing = WatchConnectivitySyncCoordinator.shared,
        healthManager: any WorkoutHealthManaging = NoopWorkoutHealthManager(),
        notificationCenter: NotificationCenter = .default,
        now: @escaping () -> Date = Date.init,
        timerManager: any TimerManaging = TimerManager(),
        hapticManager: any HapticManaging = HapticManager(),
        detectionManager: any SquatDetectionManaging = SquatDetectionManager(),
        motionSampler: any SquatMotionSampling = NoopSquatMotionSampler(),
        detectionMode: SquatDetectionMode = .live,
        internalDebugEnabled: Bool = false,
        tempoCueInterval: TimeInterval = WorkoutSessionViewModel.defaultTempoCueInterval
    ) {
        self.configStore = configStore
        self.calibrationStore = calibrationStore
        self.syncCoordinator = syncCoordinator
        self.healthManager = healthManager
        self.notificationCenter = notificationCenter
        self.now = now
        self.config = config ?? configStore.loadConfig()
        self.timerManager = timerManager
        self.hapticManager = hapticManager
        self.detectionManager = detectionManager
        self.motionSampler = motionSampler
        self.detectionMode = detectionMode
        self.internalDebugEnabled = internalDebugEnabled
        self.tempoCueInterval = tempoCueInterval
        self.calibrationProfile = calibrationStore.loadCalibrationProfile()
        observeSyncPayloads()
    }

    func startWorkout() {
        guard isCalibrationInProgress == false else { return }
        applyPendingConfigIfNeeded()
        stopDetectionPipeline()
        resetWorkoutRuntime()
        configureInternalDiagnosticsHandlers()

        if detectionMode == .live, calibrationProfile == nil {
            startCalibrationAndThenCountdown()
            return
        }

        startCountdown()
    }

    private func resetWorkoutRuntime() {
        progress = .empty
        pauseContext = nil
        countdownRemainingSeconds = 0
        sessionStartedAt = nil
        hasPreparedHealthWorkout = false
        healthStatusMessage = nil
        resetInternalDiagnosticsRuntime()
    }

    private func resetInternalDiagnosticsRuntime() {
        liveObservationMessage = nil
        motionSamplingAvailable = nil
        hasReceivedDeviceMotion = false
        lastDeviceMotionTimestamp = nil
        lastCalibrationDepthAngle = nil
        lastCalibrationPitchDelta = nil
        lastCalibrationRepsCompleted = nil
        lastCalibrationRepsTarget = nil
        lastGeneratedFullDepthAngle = nil
        lastGeneratedFullDepthPitchDelta = nil
        lastLiveNormalizedDepth = nil
        lastLiveWristRaiseMagnitude = nil
        lastLiveStandingStable = nil
        lastObservedMotionState = .standing
        lastNoRepReason = nil
    }

    private func startCalibrationAndThenCountdown() {
        isCalibrationInProgress = true
        detectionStatusMessage = "首次训练需要校准：先保持站立稳定，再按提示连续完成深蹲。"

        motionSampler.startCalibration(
            progress: { [weak self] phase in
                self?.handleCalibrationProgress(phase)
            },
            completion: { [weak self] result in
                self?.handleCalibrationResult(result)
            }
        )
    }

    private func handleCalibrationProgress(_ phase: SquatCalibrationPhase) {
        switch phase {
        case .preparingStanding(let secondsRemaining):
            detectionStatusMessage = "校准准备中：请保持站立稳定（约 \(secondsRemaining) 秒）"
        case .capturingSquats(let repsCompleted, let repsTarget):
            detectionStatusMessage = "校准进行中：已记录 \(repsCompleted)/\(repsTarget) 次深蹲"
        case .analyzing:
            detectionStatusMessage = "校准数据分析中，请稍候…"
        }
    }

    private func handleCalibrationResult(_ result: SquatCalibrationResult) {
        isCalibrationInProgress = false

        switch result {
        case .success(let profile):
            calibrationProfile = profile
            calibrationStore.saveCalibrationProfile(profile)
            detectionStatusMessage = "校准完成，已保存本地校准结果。"
            startCountdown()
        case .failure(let reason):
            calibrationProfile = nil
            detectionStatusMessage = calibrationFailureMessage(for: reason)
            state = .idle
        }
    }

    private func startCountdown() {
        countdownRemainingSeconds = config.countdownSeconds
        state = .countdown
        startTimer(.countdown(durationSeconds: config.countdownSeconds))
    }

    func cancelCountdown() {
        guard state == .countdown else { return }
        returnToHome()
    }

    func simulateRepDetection() {
        guard internalDebugEnabled else { return }
        guard state == .training else { return }
        detectionManager.simulateRep()
    }

    func resetCalibrationForDebug() {
        guard internalDebugEnabled else { return }

        stopDetectionPipeline()
        calibrationStore.clearCalibrationProfile()
        calibrationProfile = nil
        isCalibrationInProgress = false
        detectionStatusMessage = "已重置校准，下次开始训练会重新校准。"

        if state != .idle && state != .completed {
            returnToHome()
        }
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
            motionSampler.pause()
        }

        timerManager.pause()
        state = .paused

        Task {
            await healthManager.pauseWorkout()
        }
    }

    func resumeWorkout() {
        guard state == .paused, let resumeTarget = pauseContext?.resumeTarget else { return }
        pauseContext = nil
        state = resumeTarget

        if resumeTarget == .training {
            detectionManager.resume()
            motionSampler.resume()
        }

        timerManager.resume()

        Task {
            await healthManager.resumeWorkout()
        }
    }

    func completeRest() {
        guard state == .resting else { return }
        timerManager.cancel()
        progress.remainingRestSeconds = 0
        enterTrainingState(triggeredBy: .nextSetStarted)
    }

    func confirmEndWorkout() {
        guard state == .training || state == .resting || state == .paused else { return }
        discardHealthWorkout()
        returnToHome()
    }

    func restartWorkout() {
        guard state == .completed else { return }
        applyPendingConfigIfNeeded()
        startWorkout()
    }

    func returnToHome() {
        stopDetectionPipeline()
        timerManager.cancel()
        progress = .empty
        pauseContext = nil
        countdownRemainingSeconds = 0
        sessionStartedAt = nil
        hasPreparedHealthWorkout = false
        isCalibrationInProgress = false
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
        stopDetectionPipeline()

        if progress.currentSet >= config.totalSets {
            timerManager.cancel()
            progress.remainingRestSeconds = 0
            state = .completed
            hapticManager.playHighestPriority(among: [.workoutCompleted, .setCompleted, .repCompleted])
            let completedAt = now()
            let summary = latestWorkoutSummary(completedAt: completedAt)
            sendLatestWorkoutSummary(summary)
            finishHealthWorkout(summary, completedAt: completedAt)
            sessionStartedAt = nil
            hasPreparedHealthWorkout = false
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
        if internalDebugEnabled {
            detectionManager.setDiagnosticsHandler { [weak self] diagnostics in
                self?.handleDetectionDiagnostics(diagnostics)
            }
        } else {
            detectionManager.setDiagnosticsHandler(nil)
        }

        detectionManager.start(mode: detectionMode) { [weak self] event in
            self?.handleDetectionEvent(event)
        }

        guard detectionMode == .live, let calibrationProfile else {
            return
        }

        motionSampler.startLiveSampling(with: calibrationProfile) { [weak self] sample in
            self?.detectionManager.process(sample)
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
            detectionStatusMessage = "识别成功：+1"
            lastNoRepReason = nil
            applyRepIncrement()
            refreshInternalDiagnosticsMessage()
        case .motionStateChanged(let state):
            detectionStatusMessage = detectionMessage(for: state)
            lastObservedMotionState = state
            refreshInternalDiagnosticsMessage()
        }
    }

    private func enterTrainingState(triggeredBy hapticEvent: TrainingHapticEvent) {
        countdownRemainingSeconds = 0
        progress.remainingRestSeconds = 0
        state = .training

        if sessionStartedAt == nil {
            sessionStartedAt = now()
        }

        prepareHealthWorkoutIfNeeded()
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

    private func latestWorkoutSummary(completedAt: Date) -> WorkoutSummary {
        let startedAt = sessionStartedAt ?? completedAt
        let durationSeconds = max(Int(completedAt.timeIntervalSince(startedAt)), 0)
        return WorkoutSummary(
            completedAt: completedAt,
            totalSets: progress.currentSet,
            totalReps: progress.totalCompletedReps,
            durationSeconds: durationSeconds
        )
    }

    private func sendLatestWorkoutSummary(_ summary: WorkoutSummary) {
        let completedAt = summary.completedAt
        Task {
            try? await syncCoordinator.send(payload: .workoutSummary(summary, updatedAt: completedAt))
        }
    }

    private func prepareHealthWorkoutIfNeeded() {
        guard hasPreparedHealthWorkout == false, let startedAt = sessionStartedAt else {
            return
        }

        hasPreparedHealthWorkout = true

        Task { [weak self] in
            guard let self else { return }

            let result = await healthManager.prepareForWorkout(at: startedAt)

            await MainActor.run {
                self.handleHealthStartResult(result)
            }
        }
    }

    private func finishHealthWorkout(_ summary: WorkoutSummary, completedAt: Date) {
        Task { [weak self] in
            guard let self else { return }

            let result = await healthManager.finishWorkout(summary: summary, endDate: completedAt)

            await MainActor.run {
                self.handleHealthSaveResult(result)
            }
        }
    }

    private func discardHealthWorkout() {
        hasPreparedHealthWorkout = false
        sessionStartedAt = nil

        Task {
            await healthManager.discardWorkout()
        }
    }

    private func handleHealthStartResult(_ result: WorkoutHealthSessionStartResult) {
        switch result {
        case .started:
            healthAuthorizationStatus = .sharingAuthorized
            healthStatusMessage = nil
        case .skipped(let status):
            healthAuthorizationStatus = status
            healthStatusMessage = healthMessage(for: status)
        case .failed:
            healthStatusMessage = "Health 训练会话未能启动，训练仍可继续。"
        }
    }

    private func handleHealthSaveResult(_ result: WorkoutHealthSaveResult) {
        switch result {
        case .saved:
            healthStatusMessage = "本次训练已写入 Health app。"
        case .skipped(let status):
            healthAuthorizationStatus = status
            healthStatusMessage = healthMessage(for: status)
        case .failed:
            healthStatusMessage = "训练已完成，但未能写入 Health app。"
        }
    }

    private func healthMessage(for status: WorkoutHealthAuthorizationStatus) -> String? {
        switch status {
        case .sharingDenied:
            return "未授权 Health，训练仍可继续，但不会写入 Health app。"
        case .unavailable:
            return "当前设备不支持 Health 写入，训练仍可继续。"
        case .notDetermined, .sharingAuthorized:
            return nil
        }
    }

    private func stopDetectionPipeline() {
        motionSampler.stop()
        motionSampler.setDiagnosticsHandler(nil)
        detectionManager.stop()
        detectionManager.setDiagnosticsHandler(nil)
    }

    private func calibrationFailureMessage(for reason: SquatCalibrationFailureReason) -> String {
        switch reason {
        case .motionUnavailable:
            return "当前设备不支持动作采样，请检查手表传感器状态后重试。"
        case .insufficientStableSamples:
            return "校准失败：请保持站立稳定后重试。"
        case .insufficientSquatDepth:
            return "校准失败：请完成一次更完整的深蹲后重试。"
        case .insufficientReps:
            return "校准失败：有效深蹲次数不足，请按提示连续完成更多深蹲。"
        case .timedOut:
            return "校准超时：请重新开始并连续完成深蹲。"
        case .interrupted:
            return "校准已中断，请重新开始。"
        }
    }

    private func configureInternalDiagnosticsHandlers() {
        guard internalDebugEnabled else {
            motionSampler.setDiagnosticsHandler(nil)
            detectionManager.setDiagnosticsHandler(nil)
            liveObservationMessage = nil
            return
        }

        motionSampler.setDiagnosticsHandler { [weak self] diagnostics in
            self?.handleSamplingDiagnostics(diagnostics)
        }
    }

    private func handleSamplingDiagnostics(_ diagnostics: SquatSamplingDiagnostics) {
        motionSamplingAvailable = diagnostics.isDeviceMotionAvailable

        if diagnostics.didReceiveDeviceMotion {
            hasReceivedDeviceMotion = true
            lastDeviceMotionTimestamp = diagnostics.timestamp
        }

        if let depthAngle = diagnostics.calibrationDepthAngle {
            lastCalibrationDepthAngle = depthAngle
        }
        if let pitchDelta = diagnostics.calibrationPitchDelta {
            lastCalibrationPitchDelta = pitchDelta
        }
        if let repsCompleted = diagnostics.calibrationRepsCompleted {
            lastCalibrationRepsCompleted = repsCompleted
        }
        if let repsTarget = diagnostics.calibrationRepsTarget {
            lastCalibrationRepsTarget = repsTarget
        }
        if let fullDepthAngle = diagnostics.generatedFullDepthAngle {
            lastGeneratedFullDepthAngle = fullDepthAngle
        }
        if let fullDepthPitchDelta = diagnostics.generatedFullDepthPitchDelta {
            lastGeneratedFullDepthPitchDelta = fullDepthPitchDelta
        }

        refreshInternalDiagnosticsMessage()
    }

    private func handleDetectionDiagnostics(_ diagnostics: SquatDetectionDiagnostics) {
        lastLiveNormalizedDepth = diagnostics.normalizedDepth
        lastLiveWristRaiseMagnitude = diagnostics.wristRaiseMagnitude
        lastLiveStandingStable = diagnostics.isStandingStable
        lastObservedMotionState = diagnostics.currentMotionState
        if let noRepReason = diagnostics.noRepReason {
            lastNoRepReason = noRepReason
        }
        refreshInternalDiagnosticsMessage()
    }

    private func refreshInternalDiagnosticsMessage() {
        guard internalDebugEnabled else {
            return
        }

        var lines: [String] = []

        let availabilityText: String
        switch motionSamplingAvailable {
        case .some(true):
            availabilityText = "可用"
        case .some(false):
            availabilityText = "不可用"
        case .none:
            availabilityText = "未知"
        }

        let receivedText = hasReceivedDeviceMotion ? "已收到" : "未收到"
        if let timestamp = lastDeviceMotionTimestamp {
            lines.append("CMDeviceMotion: \(availabilityText) / \(receivedText) / ts:\(String(format: "%.2f", timestamp))")
        } else {
            lines.append("CMDeviceMotion: \(availabilityText) / \(receivedText)")
        }

        if let depthAngle = lastCalibrationDepthAngle,
           let pitchDelta = lastCalibrationPitchDelta,
           let repsCompleted = lastCalibrationRepsCompleted,
           let repsTarget = lastCalibrationRepsTarget {
            lines.append(
                "校准: depthAngle \(String(format: "%.3f", depthAngle)) / pitchDelta \(String(format: "%.3f", pitchDelta)) / reps \(repsCompleted)/\(repsTarget)"
            )
        }

        if let fullDepthAngle = lastGeneratedFullDepthAngle,
           let fullDepthPitchDelta = lastGeneratedFullDepthPitchDelta {
            lines.append(
                "校准Profile: fullDepthAngle \(String(format: "%.3f", fullDepthAngle)) / fullDepthPitchDelta \(String(format: "%.3f", fullDepthPitchDelta))"
            )
        }

        if let depth = lastLiveNormalizedDepth,
           let wrist = lastLiveWristRaiseMagnitude,
           let standingStable = lastLiveStandingStable {
            let standingText = standingStable ? "稳定" : "不稳定"
            lines.append(
                "Live: depth \(String(format: "%.2f", depth)) / wrist \(String(format: "%.2f", wrist)) / standing \(standingText) / state \(lastObservedMotionState.rawValue)"
            )
        } else {
            lines.append("Live: state \(lastObservedMotionState.rawValue)")
        }

        if let noRepReason = lastNoRepReason {
            lines.append("未计数原因: \(noRepReason.rawValue)（\(noRepReasonText(noRepReason))）")
        }

        liveObservationMessage = lines.joined(separator: "\n")
    }

    private func noRepReasonText(_ reason: SquatNoRepReason) -> String {
        switch reason {
        case .waitingForStableStanding:
            return "站立稳定时间不足"
        case .descendingThresholdNotReached:
            return "未过下降阈值"
        case .bottomThresholdNotReached:
            return "未到底"
        case .standingThresholdNotReached:
            return "未回正"
        case .standingUnstable:
            return "站立不稳定"
        case .wristRaiseFiltered:
            return "抬腕过滤"
        case .cooldownActive:
            return "cooldown"
        }
    }

    private func detectionMessage(for state: SquatMotionState) -> String {
        switch state {
        case .standing:
            return "识别中：保持稳定站立"
        case .descending:
            return "识别中：检测到下蹲动作"
        case .bottom:
            return "识别中：到达最低点"
        case .ascending:
            return "识别中：检测到起身动作"
        case .repCompleted:
            return "识别中：本次动作完成"
        }
    }
}
