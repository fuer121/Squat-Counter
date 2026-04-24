import Foundation

enum SquatDetectionEvent: Codable, Equatable, Sendable {
    case repDetected
    case motionStateChanged(SquatMotionState)
}

enum SquatNoRepReason: String, Codable, Equatable, Sendable {
    case waitingForStableStanding
    case descendingThresholdNotReached
    case bottomThresholdNotReached
    case standingThresholdNotReached
    case standingUnstable
    case wristRaiseFiltered
    case cooldownActive
}

struct SquatDetectionDiagnostics: Equatable, Sendable {
    let timestamp: TimeInterval
    let normalizedDepth: Double
    let wristRaiseMagnitude: Double
    let isStandingStable: Bool
    let currentMotionState: SquatMotionState
    let noRepReason: SquatNoRepReason?
}

enum SquatSamplingMode: String, Equatable, Sendable {
    case calibration
    case live
}

struct SquatSamplingDiagnostics: Equatable, Sendable {
    let mode: SquatSamplingMode
    let isDeviceMotionAvailable: Bool
    let didReceiveDeviceMotion: Bool
    let timestamp: TimeInterval?
    let calibrationDepthAngle: Double?
    let calibrationPitchDelta: Double?
    let calibrationRepsCompleted: Int?
    let calibrationRepsTarget: Int?
    let generatedFullDepthAngle: Double?
    let generatedFullDepthPitchDelta: Double?
}

struct SquatCalibrationRepCompletionThresholds: Equatable, Sendable {
    let angle: Double
    let pitch: Double
}

struct SquatCalibrationRepCompletionPolicy: Equatable, Sendable {
    let angleRecoveryRatio: Double
    let pitchRecoveryRatio: Double
    let minimumAngleThreshold: Double
    let minimumPitchThreshold: Double
    let maximumAngleThreshold: Double
    let maximumPitchThreshold: Double
    let stabilityDuration: TimeInterval

    init(
        angleRecoveryRatio: Double = 0.45,
        pitchRecoveryRatio: Double = 0.45,
        minimumAngleThreshold: Double = 0.08,
        minimumPitchThreshold: Double = 0.07,
        maximumAngleThreshold: Double = 0.2,
        maximumPitchThreshold: Double = 0.2,
        stabilityDuration: TimeInterval = 0.12
    ) {
        self.angleRecoveryRatio = angleRecoveryRatio.clamped(to: 0.2...0.8)
        self.pitchRecoveryRatio = pitchRecoveryRatio.clamped(to: 0.2...0.8)
        self.minimumAngleThreshold = minimumAngleThreshold.clamped(to: 0.03...0.2)
        self.minimumPitchThreshold = minimumPitchThreshold.clamped(to: 0.03...0.2)
        self.maximumAngleThreshold = maximumAngleThreshold.clamped(to: self.minimumAngleThreshold...0.3)
        self.maximumPitchThreshold = maximumPitchThreshold.clamped(to: self.minimumPitchThreshold...0.3)
        self.stabilityDuration = max(stabilityDuration, 0.0)
    }

    func thresholds(
        peakAngle: Double,
        peakPitch: Double,
        standingAngleThreshold: Double,
        standingPitchThreshold: Double
    ) -> SquatCalibrationRepCompletionThresholds {
        let angle = max(
            standingAngleThreshold,
            max(minimumAngleThreshold, peakAngle * angleRecoveryRatio)
        )
        .clamped(to: minimumAngleThreshold...maximumAngleThreshold)

        let pitch = max(
            standingPitchThreshold,
            max(minimumPitchThreshold, peakPitch * pitchRecoveryRatio)
        )
        .clamped(to: minimumPitchThreshold...maximumPitchThreshold)

        return SquatCalibrationRepCompletionThresholds(angle: angle, pitch: pitch)
    }
}

enum SquatDetectionMode: String, Codable, CaseIterable, Sendable {
    case simulation
    case live
}

struct SquatDetectionThresholds: Equatable, Sendable {
    let descendingThreshold: Double
    let bottomThreshold: Double
    let ascendingThreshold: Double
    let standingThreshold: Double
    let standingStabilityDuration: TimeInterval
    let cooldownDuration: TimeInterval
    let maximumWristRaiseMagnitude: Double

    init(
        descendingThreshold: Double = 0.2,
        bottomThreshold: Double = 0.48,
        ascendingThreshold: Double = 0.28,
        standingThreshold: Double = 0.16,
        standingStabilityDuration: TimeInterval = 0.2,
        cooldownDuration: TimeInterval = 0.8,
        maximumWristRaiseMagnitude: Double = 0.6
    ) {
        let clampedStanding = standingThreshold.clamped(to: 0.0...0.35)
        let clampedDescending = max(descendingThreshold.clamped(to: 0.1...0.8), clampedStanding + 0.04)
        let clampedBottom = max(bottomThreshold.clamped(to: 0.22...1.0), clampedDescending + 0.08)
        let clampedAscending = ascendingThreshold.clamped(to: (clampedStanding + 0.05)...(clampedBottom - 0.05))

        self.descendingThreshold = clampedDescending
        self.bottomThreshold = clampedBottom
        self.ascendingThreshold = clampedAscending
        self.standingThreshold = clampedStanding
        self.standingStabilityDuration = max(standingStabilityDuration, 0.0)
        self.cooldownDuration = max(cooldownDuration, 0.0)
        self.maximumWristRaiseMagnitude = maximumWristRaiseMagnitude.clamped(to: 0.0...1.0)
    }
}

struct SquatMotionSample: Equatable, Sendable {
    let timestamp: TimeInterval
    let normalizedDepth: Double
    let wristRaiseMagnitude: Double
    let isStandingStable: Bool

    init(
        timestamp: TimeInterval,
        normalizedDepth: Double,
        wristRaiseMagnitude: Double = 0.0,
        isStandingStable: Bool = true
    ) {
        self.timestamp = timestamp
        self.normalizedDepth = normalizedDepth.clamped(to: 0.0...1.0)
        self.wristRaiseMagnitude = wristRaiseMagnitude.clamped(to: 0.0...1.0)
        self.isStandingStable = isStandingStable
    }
}

struct SquatCalibrationProfile: Codable, Equatable, Sendable {
    let standingGravityX: Double
    let standingGravityY: Double
    let standingGravityZ: Double
    let standingPitch: Double
    let fullDepthAngle: Double
    let fullDepthPitchDelta: Double
    let standingAngleTolerance: Double
    let wristRaiseRateReference: Double

    init(
        standingGravityX: Double,
        standingGravityY: Double,
        standingGravityZ: Double,
        standingPitch: Double = 0.0,
        fullDepthAngle: Double,
        fullDepthPitchDelta: Double = 0.18,
        standingAngleTolerance: Double = 0.12,
        wristRaiseRateReference: Double = 5.0
    ) {
        let normalized = SquatCalibrationProfile.normalizedVector(
            x: standingGravityX,
            y: standingGravityY,
            z: standingGravityZ
        )

        self.standingGravityX = normalized.x
        self.standingGravityY = normalized.y
        self.standingGravityZ = normalized.z
        self.standingPitch = standingPitch.clamped(to: -2.5...2.5)
        self.fullDepthAngle = fullDepthAngle.clamped(to: 0.12...1.6)
        self.fullDepthPitchDelta = fullDepthPitchDelta.clamped(to: 0.08...1.2)
        self.standingAngleTolerance = standingAngleTolerance.clamped(to: 0.03...0.3)
        self.wristRaiseRateReference = wristRaiseRateReference.clamped(to: 1.0...12.0)
    }

    init() {
        self.init(
            standingGravityX: 0.0,
            standingGravityY: -1.0,
            standingGravityZ: 0.0,
            standingPitch: 0.0,
            fullDepthAngle: 0.75,
            fullDepthPitchDelta: 0.18,
            standingAngleTolerance: 0.12,
            wristRaiseRateReference: 5.0
        )
    }

    var standingGravityVector: (x: Double, y: Double, z: Double) {
        (standingGravityX, standingGravityY, standingGravityZ)
    }

    private enum CodingKeys: String, CodingKey {
        case standingGravityX
        case standingGravityY
        case standingGravityZ
        case standingPitch
        case fullDepthAngle
        case fullDepthPitchDelta
        case standingAngleTolerance
        case wristRaiseRateReference
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            standingGravityX: try container.decode(Double.self, forKey: .standingGravityX),
            standingGravityY: try container.decode(Double.self, forKey: .standingGravityY),
            standingGravityZ: try container.decode(Double.self, forKey: .standingGravityZ),
            standingPitch: try container.decodeIfPresent(Double.self, forKey: .standingPitch) ?? 0.0,
            fullDepthAngle: try container.decode(Double.self, forKey: .fullDepthAngle),
            fullDepthPitchDelta: try container.decodeIfPresent(Double.self, forKey: .fullDepthPitchDelta) ?? 0.18,
            standingAngleTolerance: try container.decodeIfPresent(Double.self, forKey: .standingAngleTolerance) ?? 0.12,
            wristRaiseRateReference: try container.decodeIfPresent(Double.self, forKey: .wristRaiseRateReference) ?? 5.0
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(standingGravityX, forKey: .standingGravityX)
        try container.encode(standingGravityY, forKey: .standingGravityY)
        try container.encode(standingGravityZ, forKey: .standingGravityZ)
        try container.encode(standingPitch, forKey: .standingPitch)
        try container.encode(fullDepthAngle, forKey: .fullDepthAngle)
        try container.encode(fullDepthPitchDelta, forKey: .fullDepthPitchDelta)
        try container.encode(standingAngleTolerance, forKey: .standingAngleTolerance)
        try container.encode(wristRaiseRateReference, forKey: .wristRaiseRateReference)
    }

    private static func normalizedVector(x: Double, y: Double, z: Double) -> (x: Double, y: Double, z: Double) {
        let magnitude = sqrt((x * x) + (y * y) + (z * z))
        guard magnitude > 0.0001 else {
            return (0.0, -1.0, 0.0)
        }
        return (x / magnitude, y / magnitude, z / magnitude)
    }
}

enum SquatCalibrationFailureReason: String, Codable, Equatable, Sendable {
    case motionUnavailable
    case insufficientStableSamples
    case insufficientSquatDepth
    case insufficientReps
    case timedOut
    case interrupted
}

enum SquatCalibrationResult: Equatable, Sendable {
    case success(SquatCalibrationProfile)
    case failure(SquatCalibrationFailureReason)
}

enum SquatCalibrationPhase: Equatable, Sendable {
    case preparingStanding(secondsRemaining: Int)
    case capturingSquats(repsCompleted: Int, repsTarget: Int)
    case analyzing
}

protocol SquatMotionSampling: AnyObject {
    var isSamplingActive: Bool { get }
    var isPaused: Bool { get }

    func startCalibration(
        progress: @escaping (SquatCalibrationPhase) -> Void,
        completion: @escaping (SquatCalibrationResult) -> Void
    )
    func startLiveSampling(with profile: SquatCalibrationProfile, handler: @escaping (SquatMotionSample) -> Void)
    func pause()
    func resume()
    func stop()
    func setDiagnosticsHandler(_ handler: ((SquatSamplingDiagnostics) -> Void)?)
}

final class NoopSquatMotionSampler: SquatMotionSampling {
    private(set) var isSamplingActive = false
    private(set) var isPaused = false
    private var diagnosticsHandler: ((SquatSamplingDiagnostics) -> Void)?

    func startCalibration(
        progress: @escaping (SquatCalibrationPhase) -> Void,
        completion: @escaping (SquatCalibrationResult) -> Void
    ) {
        isSamplingActive = false
        isPaused = false
        progress(.analyzing)
        completion(.success(SquatCalibrationProfile()))
    }

    func startLiveSampling(with profile: SquatCalibrationProfile, handler: @escaping (SquatMotionSample) -> Void) {
        isSamplingActive = true
        isPaused = false
    }

    func pause() {
        guard isSamplingActive else { return }
        isPaused = true
    }

    func resume() {
        guard isSamplingActive else { return }
        isPaused = false
    }

    func stop() {
        isSamplingActive = false
        isPaused = false
    }

    func setDiagnosticsHandler(_ handler: ((SquatSamplingDiagnostics) -> Void)?) {
        diagnosticsHandler = handler
    }
}

protocol SquatDetectionManaging: AnyObject {
    var mode: SquatDetectionMode? { get }
    var isActive: Bool { get }
    var isPaused: Bool { get }
    var currentMotionState: SquatMotionState { get }
    var thresholds: SquatDetectionThresholds { get }

    func start(mode: SquatDetectionMode, handler: @escaping (SquatDetectionEvent) -> Void)
    func pause()
    func resume()
    func stop()
    func simulateRep()
    func process(_ sample: SquatMotionSample)
    func setDiagnosticsHandler(_ handler: ((SquatDetectionDiagnostics) -> Void)?)
}

final class SquatDetectionManager: SquatDetectionManaging {
    private let now: () -> TimeInterval
    private var eventHandler: ((SquatDetectionEvent) -> Void)?
    private var diagnosticsHandler: ((SquatDetectionDiagnostics) -> Void)?
    private var standingStableSince: TimeInterval?
    private var cooldownUntil: TimeInterval = 0

    private(set) var mode: SquatDetectionMode?
    private(set) var isActive = false
    private(set) var isPaused = false
    private(set) var currentMotionState: SquatMotionState = .standing
    let thresholds: SquatDetectionThresholds

    init(
        thresholds: SquatDetectionThresholds = SquatDetectionThresholds(),
        now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.thresholds = thresholds
        self.now = now
    }

    func start(mode: SquatDetectionMode, handler: @escaping (SquatDetectionEvent) -> Void) {
        resetRuntimeState()
        self.mode = mode
        self.eventHandler = handler
        isActive = true
        isPaused = false
    }

    func pause() {
        guard isActive, isPaused == false else { return }
        isPaused = true
    }

    func resume() {
        guard isActive, isPaused else { return }
        isPaused = false
    }

    func stop() {
        resetRuntimeState()
        eventHandler = nil
        mode = nil
        isActive = false
        isPaused = false
    }

    func simulateRep() {
        guard mode == .simulation, isAcceptingInput else { return }

        let timestamp = now()
        guard timestamp >= cooldownUntil else { return }

        transition(to: .descending)
        transition(to: .bottom)
        transition(to: .ascending)
        completeRep(at: timestamp)
    }

    func process(_ sample: SquatMotionSample) {
        guard mode == .live, isAcceptingInput else { return }

        if sample.timestamp < cooldownUntil {
            resetToStanding()
            updateStandingBaseline(with: sample)
            emitDiagnostics(for: sample, noRepReason: .cooldownActive)
            return
        }

        if sample.wristRaiseMagnitude > thresholds.maximumWristRaiseMagnitude,
           sample.normalizedDepth < thresholds.bottomThreshold {
            resetToStanding()
            standingStableSince = nil
            emitDiagnostics(for: sample, noRepReason: .wristRaiseFiltered)
            return
        }

        switch currentMotionState {
        case .standing:
            let canBeginDescending = hasStableStanding(at: sample.timestamp)

            if canBeginDescending, sample.normalizedDepth >= thresholds.descendingThreshold {
                standingStableSince = nil
                transition(to: .descending)
                emitDiagnostics(for: sample, noRepReason: nil)
                return
            }

            updateStandingBaseline(with: sample)
            if sample.isStandingStable == false {
                emitDiagnostics(for: sample, noRepReason: .standingUnstable)
            } else if canBeginDescending == false {
                emitDiagnostics(for: sample, noRepReason: .waitingForStableStanding)
            } else {
                emitDiagnostics(for: sample, noRepReason: .descendingThresholdNotReached)
            }
        case .descending:
            if sample.normalizedDepth >= thresholds.bottomThreshold {
                transition(to: .bottom)
                emitDiagnostics(for: sample, noRepReason: nil)
            } else if sample.normalizedDepth <= thresholds.standingThreshold {
                resetToStanding()
                updateStandingBaseline(with: sample)
                emitDiagnostics(for: sample, noRepReason: .bottomThresholdNotReached)
            } else {
                emitDiagnostics(for: sample, noRepReason: .bottomThresholdNotReached)
            }
        case .bottom:
            if sample.normalizedDepth <= thresholds.ascendingThreshold {
                transition(to: .ascending)
                emitDiagnostics(for: sample, noRepReason: nil)
            } else {
                emitDiagnostics(for: sample, noRepReason: .standingThresholdNotReached)
            }
        case .ascending:
            if sample.normalizedDepth <= thresholds.standingThreshold {
                completeRep(at: sample.timestamp)
                updateStandingBaseline(with: sample)
                emitDiagnostics(for: sample, noRepReason: nil)
            } else if sample.normalizedDepth >= thresholds.bottomThreshold {
                transition(to: .bottom)
                emitDiagnostics(for: sample, noRepReason: .standingThresholdNotReached)
            } else {
                emitDiagnostics(for: sample, noRepReason: .standingThresholdNotReached)
            }
        case .repCompleted:
            resetToStanding()
            updateStandingBaseline(with: sample)
            emitDiagnostics(for: sample, noRepReason: nil)
        }
    }

    func setDiagnosticsHandler(_ handler: ((SquatDetectionDiagnostics) -> Void)?) {
        diagnosticsHandler = handler
    }

    private var isAcceptingInput: Bool {
        isActive && isPaused == false
    }

    private func updateStandingBaseline(with sample: SquatMotionSample) {
        let isStandingCandidate = sample.normalizedDepth <= thresholds.standingThreshold
            && sample.wristRaiseMagnitude <= thresholds.maximumWristRaiseMagnitude
            && sample.isStandingStable

        guard isStandingCandidate else {
            standingStableSince = nil
            return
        }

        if standingStableSince == nil {
            standingStableSince = sample.timestamp
        }
    }

    private func hasStableStanding(at timestamp: TimeInterval) -> Bool {
        guard let standingStableSince else { return false }
        return timestamp - standingStableSince >= thresholds.standingStabilityDuration
    }

    private func transition(to state: SquatMotionState) {
        guard currentMotionState != state else { return }
        currentMotionState = state
        eventHandler?(.motionStateChanged(state))
    }

    private func completeRep(at timestamp: TimeInterval) {
        transition(to: .repCompleted)
        eventHandler?(.repDetected)
        cooldownUntil = timestamp + thresholds.cooldownDuration
        standingStableSince = nil
        currentMotionState = .repCompleted
        transition(to: .standing)
    }

    private func resetToStanding() {
        transition(to: .standing)
    }

    private func resetRuntimeState() {
        currentMotionState = .standing
        standingStableSince = nil
        cooldownUntil = 0
    }

    private func emitDiagnostics(for sample: SquatMotionSample, noRepReason: SquatNoRepReason?) {
        diagnosticsHandler?(
            SquatDetectionDiagnostics(
                timestamp: sample.timestamp,
                normalizedDepth: sample.normalizedDepth,
                wristRaiseMagnitude: sample.wristRaiseMagnitude,
                isStandingStable: sample.isStandingStable,
                currentMotionState: currentMotionState,
                noRepReason: noRepReason
            )
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
