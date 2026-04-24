import CoreMotion
import Foundation

final class WatchLiveSquatMotionSampler: SquatMotionSampling {
    private enum ActiveMode {
        case idle
        case calibrating
        case live
    }

    private enum CalibrationMotionState {
        case standing
        case descending
        case bottom
    }

    private struct MotionVector {
        let x: Double
        let y: Double
        let z: Double

        var magnitude: Double {
            sqrt((x * x) + (y * y) + (z * z))
        }

        func normalized(fallback: MotionVector = MotionVector(x: 0.0, y: -1.0, z: 0.0)) -> MotionVector {
            let value = magnitude
            guard value > 0.0001 else {
                return fallback
            }

            return MotionVector(x: x / value, y: y / value, z: z / value)
        }

        func dot(_ other: MotionVector) -> Double {
            (x * other.x) + (y * other.y) + (z * other.z)
        }

        func angle(to other: MotionVector) -> Double {
            acos(dot(other).clamped(to: -1.0...1.0))
        }

        static func average(_ vectors: [MotionVector]) -> MotionVector {
            guard vectors.isEmpty == false else {
                return MotionVector(x: 0.0, y: -1.0, z: 0.0)
            }

            let sums = vectors.reduce((x: 0.0, y: 0.0, z: 0.0)) { partial, vector in
                (x: partial.x + vector.x, y: partial.y + vector.y, z: partial.z + vector.z)
            }

            return MotionVector(
                x: sums.x / Double(vectors.count),
                y: sums.y / Double(vectors.count),
                z: sums.z / Double(vectors.count)
            )
            .normalized()
        }
    }

    private let motionManager: CMMotionManager

    private let standingPreparationDuration: TimeInterval = 2.0
    private let calibrationWindowDuration: TimeInterval = 35.0
    private let minimumStandingSamples = 30
    private let targetCalibrationReps = 10
    private let minimumCalibrationReps = 6

    private let descendingAngleThreshold: Double = 0.08
    private let bottomAngleThreshold: Double = 0.16
    private let standingAngleThreshold: Double = 0.06
    private let descendingPitchThreshold: Double = 0.06
    private let bottomPitchThreshold: Double = 0.14
    private let standingPitchThreshold: Double = 0.05
    private let repCompletionPolicy = SquatCalibrationRepCompletionPolicy()

    private var activeMode: ActiveMode = .idle
    private(set) var isPaused = false

    private var calibrationStartedAt: TimeInterval = 0
    private var calibrationStandingSamples: [MotionVector] = []
    private var calibrationStandingPitchSamples: [Double] = []
    private var calibrationBaseline: MotionVector?
    private var calibrationStandingPitch: Double?
    private var calibrationMotionState: CalibrationMotionState = .standing
    private var currentRepPeakAngle: Double = 0
    private var currentRepPeakPitch: Double = 0
    private var standingRecoveryCandidateSince: TimeInterval?
    private var completedCalibrationReps = 0
    private var completedRepPeakAngles: [Double] = []
    private var completedRepPeakPitchDeltas: [Double] = []
    private var calibrationMaxRotationRate: Double = 0
    private var calibrationProgress: ((SquatCalibrationPhase) -> Void)?
    private var calibrationCompletion: ((SquatCalibrationResult) -> Void)?
    private var lastPreparationSecondsRemaining: Int?
    private var diagnosticsHandler: ((SquatSamplingDiagnostics) -> Void)?

    private var liveProfile: SquatCalibrationProfile?
    private var liveHandler: ((SquatMotionSample) -> Void)?

    var isSamplingActive: Bool {
        activeMode != .idle
    }

    init(motionManager: CMMotionManager = CMMotionManager()) {
        self.motionManager = motionManager
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
    }

    func startCalibration(
        progress: @escaping (SquatCalibrationPhase) -> Void,
        completion: @escaping (SquatCalibrationResult) -> Void
    ) {
        guard motionManager.isDeviceMotionAvailable else {
            emitSamplingDiagnostics(
                mode: .calibration,
                isDeviceMotionAvailable: false,
                didReceiveDeviceMotion: false
            )
            completion(.failure(.motionUnavailable))
            return
        }

        stopInternal(notifyCalibrationInterrupted: false)
        activeMode = .calibrating
        isPaused = false

        calibrationStartedAt = 0
        calibrationStandingSamples = []
        calibrationStandingPitchSamples = []
        calibrationBaseline = nil
        calibrationStandingPitch = nil
        calibrationMotionState = .standing
        currentRepPeakAngle = 0
        currentRepPeakPitch = 0
        standingRecoveryCandidateSince = nil
        completedCalibrationReps = 0
        completedRepPeakAngles = []
        completedRepPeakPitchDeltas = []
        calibrationMaxRotationRate = 0
        calibrationProgress = progress
        calibrationCompletion = completion
        lastPreparationSecondsRemaining = nil

        emitSamplingDiagnostics(
            mode: .calibration,
            isDeviceMotionAvailable: true,
            didReceiveDeviceMotion: false
        )
        progress(.preparingStanding(secondsRemaining: Int(ceil(standingPreparationDuration))))
        startDeviceMotionUpdatesIfNeeded()
    }

    func startLiveSampling(with profile: SquatCalibrationProfile, handler: @escaping (SquatMotionSample) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            emitSamplingDiagnostics(
                mode: .live,
                isDeviceMotionAvailable: false,
                didReceiveDeviceMotion: false
            )
            return
        }

        stopInternal(notifyCalibrationInterrupted: false)
        activeMode = .live
        isPaused = false
        liveProfile = profile
        liveHandler = handler
        emitSamplingDiagnostics(
            mode: .live,
            isDeviceMotionAvailable: true,
            didReceiveDeviceMotion: false
        )
        startDeviceMotionUpdatesIfNeeded()
    }

    func pause() {
        guard activeMode == .live else { return }
        isPaused = true
    }

    func resume() {
        guard activeMode == .live else { return }
        isPaused = false
    }

    func stop() {
        stopInternal(notifyCalibrationInterrupted: true)
    }

    func setDiagnosticsHandler(_ handler: ((SquatSamplingDiagnostics) -> Void)?) {
        diagnosticsHandler = handler
    }

    private func stopInternal(notifyCalibrationInterrupted: Bool) {
        let shouldNotifyInterrupted = notifyCalibrationInterrupted && activeMode == .calibrating
        let calibrationCompletion = self.calibrationCompletion

        motionManager.stopDeviceMotionUpdates()
        activeMode = .idle
        isPaused = false

        calibrationStartedAt = 0
        calibrationStandingSamples = []
        calibrationStandingPitchSamples = []
        calibrationBaseline = nil
        calibrationStandingPitch = nil
        calibrationMotionState = .standing
        currentRepPeakAngle = 0
        currentRepPeakPitch = 0
        standingRecoveryCandidateSince = nil
        completedCalibrationReps = 0
        completedRepPeakAngles = []
        completedRepPeakPitchDeltas = []
        calibrationMaxRotationRate = 0
        calibrationProgress = nil
        self.calibrationCompletion = nil
        lastPreparationSecondsRemaining = nil

        liveProfile = nil
        liveHandler = nil

        if shouldNotifyInterrupted {
            calibrationCompletion?(.failure(.interrupted))
        }
    }

    private func startDeviceMotionUpdatesIfNeeded() {
        guard motionManager.isDeviceMotionActive == false else {
            return
        }

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else {
                return
            }

            self.handleDeviceMotion(motion)
        }
    }

    private func handleDeviceMotion(_ motion: CMDeviceMotion) {
        if let mode = diagnosticsMode(from: activeMode) {
            emitSamplingDiagnostics(
                mode: mode,
                isDeviceMotionAvailable: motionManager.isDeviceMotionAvailable,
                didReceiveDeviceMotion: true,
                timestamp: motion.timestamp
            )
        }

        switch activeMode {
        case .idle:
            return
        case .calibrating:
            handleCalibrationMotion(motion)
        case .live:
            handleLiveMotion(motion)
        }
    }

    private func handleCalibrationMotion(_ motion: CMDeviceMotion) {
        if calibrationStartedAt == 0 {
            calibrationStartedAt = motion.timestamp
        }

        let elapsed = motion.timestamp - calibrationStartedAt
        let gravity = MotionVector(x: motion.gravity.x, y: motion.gravity.y, z: motion.gravity.z).normalized()
        let pitch = motion.attitude.pitch
        let rotationRateMagnitude = MotionVector(
            x: motion.rotationRate.x,
            y: motion.rotationRate.y,
            z: motion.rotationRate.z
        ).magnitude
        calibrationMaxRotationRate = max(calibrationMaxRotationRate, rotationRateMagnitude)

        if elapsed <= standingPreparationDuration {
            calibrationStandingSamples.append(gravity)
            calibrationStandingPitchSamples.append(pitch)
            reportPreparationProgress(elapsed: elapsed)
            return
        }

        if calibrationBaseline == nil || calibrationStandingPitch == nil {
            calibrationStandingSamples.append(gravity)
            calibrationStandingPitchSamples.append(pitch)

            guard calibrationStandingSamples.count >= minimumStandingSamples else {
                if elapsed >= standingPreparationDuration + 5.0 {
                    emitCalibrationResult(.failure(.insufficientStableSamples))
                }
                return
            }

            calibrationBaseline = MotionVector.average(calibrationStandingSamples)
            calibrationStandingPitch = average(calibrationStandingPitchSamples)
            calibrationProgress?(.capturingSquats(repsCompleted: 0, repsTarget: targetCalibrationReps))
            return
        }

        guard let baseline = calibrationBaseline, let standingPitch = calibrationStandingPitch else {
            emitCalibrationResult(.failure(.insufficientStableSamples))
            return
        }

        let depthAngle = gravity.angle(to: baseline)
        let pitchDelta = abs(pitch - standingPitch)
        updateCalibrationMotionState(timestamp: motion.timestamp, depthAngle: depthAngle, pitchDelta: pitchDelta)
        emitSamplingDiagnostics(
            mode: .calibration,
            isDeviceMotionAvailable: motionManager.isDeviceMotionAvailable,
            didReceiveDeviceMotion: true,
            timestamp: motion.timestamp,
            calibrationDepthAngle: depthAngle,
            calibrationPitchDelta: pitchDelta,
            calibrationRepsCompleted: completedCalibrationReps,
            calibrationRepsTarget: targetCalibrationReps
        )

        if completedCalibrationReps >= targetCalibrationReps {
            calibrationProgress?(.analyzing)
            emitCalibrationResult(buildCalibrationResult(from: baseline, standingPitch: standingPitch))
            return
        }

        if elapsed >= calibrationWindowDuration {
            calibrationProgress?(.analyzing)
            if completedCalibrationReps >= minimumCalibrationReps {
                emitCalibrationResult(buildCalibrationResult(from: baseline, standingPitch: standingPitch))
            } else if completedCalibrationReps > 0 {
                emitCalibrationResult(.failure(.insufficientReps))
            } else {
                emitCalibrationResult(.failure(.timedOut))
            }
        }
    }

    private func reportPreparationProgress(elapsed: TimeInterval) {
        let remaining = max(Int(ceil(standingPreparationDuration - elapsed)), 0)
        guard lastPreparationSecondsRemaining != remaining else {
            return
        }

        lastPreparationSecondsRemaining = remaining
        calibrationProgress?(.preparingStanding(secondsRemaining: remaining))
    }

    private func updateCalibrationMotionState(timestamp: TimeInterval, depthAngle: Double, pitchDelta: Double) {
        switch calibrationMotionState {
        case .standing:
            if depthAngle >= descendingAngleThreshold || pitchDelta >= descendingPitchThreshold {
                calibrationMotionState = .descending
                currentRepPeakAngle = depthAngle
                currentRepPeakPitch = pitchDelta
            }
            standingRecoveryCandidateSince = nil
        case .descending:
            currentRepPeakAngle = max(currentRepPeakAngle, depthAngle)
            currentRepPeakPitch = max(currentRepPeakPitch, pitchDelta)

            if depthAngle >= bottomAngleThreshold || pitchDelta >= bottomPitchThreshold {
                calibrationMotionState = .bottom
            } else if depthAngle <= standingAngleThreshold && pitchDelta <= standingPitchThreshold {
                calibrationMotionState = .standing
                currentRepPeakAngle = 0
                currentRepPeakPitch = 0
            }
            standingRecoveryCandidateSince = nil
        case .bottom:
            currentRepPeakAngle = max(currentRepPeakAngle, depthAngle)
            currentRepPeakPitch = max(currentRepPeakPitch, pitchDelta)

            let reachedStandingRecovery = repCompletionPolicy.hasRecovered(
                depthAngle: depthAngle,
                pitchDelta: pitchDelta,
                peakAngle: currentRepPeakAngle,
                peakPitch: currentRepPeakPitch,
                standingAngleThreshold: standingAngleThreshold,
                standingPitchThreshold: standingPitchThreshold
            )

            if reachedStandingRecovery {
                if standingRecoveryCandidateSince == nil {
                    standingRecoveryCandidateSince = timestamp
                }

                let stableDuration = timestamp - (standingRecoveryCandidateSince ?? timestamp)
                if stableDuration >= repCompletionPolicy.stabilityDuration {
                    completedCalibrationReps += 1
                    completedRepPeakAngles.append(currentRepPeakAngle)
                    completedRepPeakPitchDeltas.append(currentRepPeakPitch)
                    calibrationMotionState = .standing
                    currentRepPeakAngle = 0
                    currentRepPeakPitch = 0
                    standingRecoveryCandidateSince = nil
                    calibrationProgress?(
                        .capturingSquats(
                            repsCompleted: min(completedCalibrationReps, targetCalibrationReps),
                            repsTarget: targetCalibrationReps
                        )
                    )
                }
            } else {
                standingRecoveryCandidateSince = nil
            }
        }
    }

    private func buildCalibrationResult(from baseline: MotionVector, standingPitch: Double) -> SquatCalibrationResult {
        let maxAngle = percentile(of: completedRepPeakAngles, percentile: 0.75)
        let maxPitch = percentile(of: completedRepPeakPitchDeltas, percentile: 0.75)

        let fullDepthAngle = max(maxAngle, 0.14)
        let fullDepthPitchDelta = max(maxPitch, 0.1)

        guard fullDepthAngle >= 0.12 || fullDepthPitchDelta >= 0.09 else {
            return .failure(.insufficientSquatDepth)
        }

        let standingAngleTolerance = (fullDepthAngle * 0.3).clamped(to: 0.06...0.24)
        let wristRaiseRateReference = max(calibrationMaxRotationRate * 0.75, 3.0)

        return .success(
            SquatCalibrationProfile(
                standingGravityX: baseline.x,
                standingGravityY: baseline.y,
                standingGravityZ: baseline.z,
                standingPitch: standingPitch,
                fullDepthAngle: fullDepthAngle,
                fullDepthPitchDelta: fullDepthPitchDelta,
                standingAngleTolerance: standingAngleTolerance,
                wristRaiseRateReference: wristRaiseRateReference
            )
        )
    }

    private func emitCalibrationResult(_ result: SquatCalibrationResult) {
        if case .success(let profile) = result {
            emitSamplingDiagnostics(
                mode: .calibration,
                isDeviceMotionAvailable: motionManager.isDeviceMotionAvailable,
                didReceiveDeviceMotion: true,
                generatedFullDepthAngle: profile.fullDepthAngle,
                generatedFullDepthPitchDelta: profile.fullDepthPitchDelta
            )
        }

        let completion = calibrationCompletion
        stopInternal(notifyCalibrationInterrupted: false)
        completion?(result)
    }

    private func handleLiveMotion(_ motion: CMDeviceMotion) {
        guard isPaused == false else {
            return
        }

        guard let profile = liveProfile, let handler = liveHandler else {
            return
        }

        let currentGravity = MotionVector(x: motion.gravity.x, y: motion.gravity.y, z: motion.gravity.z).normalized()
        let standingGravity = MotionVector(
            x: profile.standingGravityVector.x,
            y: profile.standingGravityVector.y,
            z: profile.standingGravityVector.z
        ).normalized()

        let angle = currentGravity.angle(to: standingGravity)
        let pitchDelta = abs(motion.attitude.pitch - profile.standingPitch)

        let angleDepth = (angle / profile.fullDepthAngle).clamped(to: 0.0...1.0)
        let pitchDepth = (pitchDelta / profile.fullDepthPitchDelta).clamped(to: 0.0...1.0)
        let normalizedDepth = max(angleDepth, pitchDepth)

        let rotationRateMagnitude = MotionVector(
            x: motion.rotationRate.x,
            y: motion.rotationRate.y,
            z: motion.rotationRate.z
        ).magnitude
        let wristRaiseMagnitude = (rotationRateMagnitude / profile.wristRaiseRateReference).clamped(to: 0.0...1.0)

        let pitchStandingTolerance = max(profile.fullDepthPitchDelta * 0.35, 0.05)
        let isStandingStable = angle <= profile.standingAngleTolerance
            && pitchDelta <= pitchStandingTolerance
            && wristRaiseMagnitude <= 0.6

        handler(
            SquatMotionSample(
                timestamp: motion.timestamp,
                normalizedDepth: normalizedDepth,
                wristRaiseMagnitude: wristRaiseMagnitude,
                isStandingStable: isStandingStable
            )
        )
    }

    private func average(_ values: [Double]) -> Double {
        guard values.isEmpty == false else { return 0.0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func percentile(of values: [Double], percentile: Double) -> Double {
        guard values.isEmpty == false else { return 0.0 }
        let sorted = values.sorted()
        let clamped = percentile.clamped(to: 0.0...1.0)
        let index = Int(Double(sorted.count - 1) * clamped)
        return sorted[index]
    }

    private func diagnosticsMode(from mode: ActiveMode) -> SquatSamplingMode? {
        switch mode {
        case .calibrating:
            return .calibration
        case .live:
            return .live
        case .idle:
            return nil
        }
    }

    private func emitSamplingDiagnostics(
        mode: SquatSamplingMode,
        isDeviceMotionAvailable: Bool,
        didReceiveDeviceMotion: Bool,
        timestamp: TimeInterval? = nil,
        calibrationDepthAngle: Double? = nil,
        calibrationPitchDelta: Double? = nil,
        calibrationRepsCompleted: Int? = nil,
        calibrationRepsTarget: Int? = nil,
        generatedFullDepthAngle: Double? = nil,
        generatedFullDepthPitchDelta: Double? = nil
    ) {
        diagnosticsHandler?(
            SquatSamplingDiagnostics(
                mode: mode,
                isDeviceMotionAvailable: isDeviceMotionAvailable,
                didReceiveDeviceMotion: didReceiveDeviceMotion,
                timestamp: timestamp,
                calibrationDepthAngle: calibrationDepthAngle,
                calibrationPitchDelta: calibrationPitchDelta,
                calibrationRepsCompleted: calibrationRepsCompleted,
                calibrationRepsTarget: calibrationRepsTarget,
                generatedFullDepthAngle: generatedFullDepthAngle,
                generatedFullDepthPitchDelta: generatedFullDepthPitchDelta
            )
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
