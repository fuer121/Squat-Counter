import CoreMotion
import Foundation

final class WatchLiveSquatMotionSampler: SquatMotionSampling {
    private enum ActiveMode {
        case idle
        case calibrating
        case live
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

        func angle(to other: MotionVector) -> Double {
            acos(dot(other).clamped(to: -1.0...1.0))
        }
    }

    private let motionManager: CMMotionManager

    private let standingCaptureDuration: TimeInterval = 1.5
    private let calibrationDuration: TimeInterval = 6.0
    private let minimumStandingSamples = 20
    private let minimumSquatDepthAngle = 0.28

    private var activeMode: ActiveMode = .idle
    private(set) var isPaused = false

    private var calibrationStartedAt: TimeInterval = 0
    private var calibrationStandingSamples: [MotionVector] = []
    private var calibrationBaseline: MotionVector?
    private var calibrationMaxDepthAngle: Double = 0
    private var calibrationMaxRotationRate: Double = 0
    private var calibrationHandler: ((SquatCalibrationResult) -> Void)?

    private var liveProfile: SquatCalibrationProfile?
    private var liveHandler: ((SquatMotionSample) -> Void)?

    var isSamplingActive: Bool {
        activeMode != .idle
    }

    init(motionManager: CMMotionManager = CMMotionManager()) {
        self.motionManager = motionManager
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
    }

    func startCalibration(handler: @escaping (SquatCalibrationResult) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            handler(.failure(.motionUnavailable))
            return
        }

        stopInternal(notifyCalibrationInterrupted: false)
        activeMode = .calibrating
        isPaused = false
        calibrationStartedAt = 0
        calibrationStandingSamples = []
        calibrationBaseline = nil
        calibrationMaxDepthAngle = 0
        calibrationMaxRotationRate = 0
        calibrationHandler = handler
        startDeviceMotionUpdatesIfNeeded()
    }

    func startLiveSampling(with profile: SquatCalibrationProfile, handler: @escaping (SquatMotionSample) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            return
        }

        stopInternal(notifyCalibrationInterrupted: false)
        activeMode = .live
        isPaused = false
        liveProfile = profile
        liveHandler = handler
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

    private func stopInternal(notifyCalibrationInterrupted: Bool) {
        let shouldNotifyCalibrationInterrupted = notifyCalibrationInterrupted && activeMode == .calibrating
        let calibrationHandler = self.calibrationHandler

        motionManager.stopDeviceMotionUpdates()
        activeMode = .idle
        isPaused = false

        calibrationStartedAt = 0
        calibrationStandingSamples = []
        calibrationBaseline = nil
        calibrationMaxDepthAngle = 0
        calibrationMaxRotationRate = 0
        self.calibrationHandler = nil

        liveProfile = nil
        liveHandler = nil

        if shouldNotifyCalibrationInterrupted {
            calibrationHandler?(.failure(.interrupted))
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
        let timestamp = motion.timestamp
        if calibrationStartedAt == 0 {
            calibrationStartedAt = timestamp
        }

        let elapsed = timestamp - calibrationStartedAt
        let gravity = MotionVector(x: motion.gravity.x, y: motion.gravity.y, z: motion.gravity.z).normalized()
        let rotationRateMagnitude = MotionVector(
            x: motion.rotationRate.x,
            y: motion.rotationRate.y,
            z: motion.rotationRate.z
        ).magnitude

        if elapsed <= standingCaptureDuration {
            calibrationStandingSamples.append(gravity)
            return
        }

        if calibrationBaseline == nil {
            guard calibrationStandingSamples.count >= minimumStandingSamples else {
                emitCalibrationResult(.failure(.insufficientStableSamples))
                return
            }

            calibrationBaseline = MotionVector.average(calibrationStandingSamples)
        }

        guard let baseline = calibrationBaseline else {
            emitCalibrationResult(.failure(.insufficientStableSamples))
            return
        }

        let depthAngle = gravity.angle(to: baseline)
        calibrationMaxDepthAngle = max(calibrationMaxDepthAngle, depthAngle)
        calibrationMaxRotationRate = max(calibrationMaxRotationRate, rotationRateMagnitude)

        guard elapsed >= calibrationDuration else {
            return
        }

        guard calibrationMaxDepthAngle >= minimumSquatDepthAngle else {
            emitCalibrationResult(.failure(.insufficientSquatDepth))
            return
        }

        let fullDepthAngle = max(calibrationMaxDepthAngle, 0.55)
        let standingAngleTolerance = (fullDepthAngle * 0.18).clamped(to: 0.08...0.2)
        let wristRaiseRateReference = max(calibrationMaxRotationRate, 4.0)

        let profile = SquatCalibrationProfile(
            standingGravityX: baseline.x,
            standingGravityY: baseline.y,
            standingGravityZ: baseline.z,
            fullDepthAngle: fullDepthAngle,
            standingAngleTolerance: standingAngleTolerance,
            wristRaiseRateReference: wristRaiseRateReference
        )

        emitCalibrationResult(.success(profile))
    }

    private func emitCalibrationResult(_ result: SquatCalibrationResult) {
        let handler = calibrationHandler
        stopInternal(notifyCalibrationInterrupted: false)
        handler?(result)
    }

    private func handleLiveMotion(_ motion: CMDeviceMotion) {
        guard isPaused == false else {
            return
        }

        guard
            let profile = liveProfile,
            let handler = liveHandler
        else {
            return
        }

        let currentGravity = MotionVector(x: motion.gravity.x, y: motion.gravity.y, z: motion.gravity.z).normalized()
        let standingGravity = MotionVector(
            x: profile.standingGravityVector.x,
            y: profile.standingGravityVector.y,
            z: profile.standingGravityVector.z
        ).normalized()

        let angle = currentGravity.angle(to: standingGravity)
        let normalizedDepth = (angle / profile.fullDepthAngle).clamped(to: 0.0...1.0)

        let rotationRateMagnitude = MotionVector(
            x: motion.rotationRate.x,
            y: motion.rotationRate.y,
            z: motion.rotationRate.z
        ).magnitude
        let wristRaiseMagnitude = (rotationRateMagnitude / profile.wristRaiseRateReference).clamped(to: 0.0...1.0)

        let isStandingStable = angle <= profile.standingAngleTolerance && wristRaiseMagnitude <= 0.35

        handler(
            SquatMotionSample(
                timestamp: motion.timestamp,
                normalizedDepth: normalizedDepth,
                wristRaiseMagnitude: wristRaiseMagnitude,
                isStandingStable: isStandingStable
            )
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
