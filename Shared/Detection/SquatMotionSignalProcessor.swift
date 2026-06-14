import Foundation

/// Tunable constants for translating raw device motion into a normalized
/// squat-depth signal. Defaults are reasonable starting points but **must be
/// calibrated against real squat data on-device** to be accurate — see
/// `docs/knowledge/SQUAT_DETECTION_CALIBRATION.md`.
struct SquatSignalProcessingConfig: Equatable, Sendable {
    /// Angular deviation (radians) of the gravity vector from the standing
    /// baseline that maps to `normalizedDepth == 1.0` (a full-depth squat).
    /// Wrist motion during a deep squat typically swings the device 50–80°.
    let fullDepthAngle: Double

    /// Deviation (radians) below which we treat the device as essentially at
    /// the standing baseline. Keeps small sway from registering as depth.
    let standingAngleTolerance: Double

    /// User-acceleration magnitude (in g) below which a sample is considered
    /// mechanically "quiet" enough to be a stable standing candidate.
    let standingAccelerationTolerance: Double

    /// Rotation-rate magnitude (rad/s) below which a sample is considered
    /// rotationally stable.
    let standingRotationTolerance: Double

    /// Smoothing factor (0...1) for the exponential moving average applied to
    /// the depth signal. Lower = smoother but laggier.
    let depthSmoothingFactor: Double

    /// How quickly the standing baseline re-calibrates toward the current
    /// gravity direction while standing (0...1 per stable sample).
    let baselineAdaptationFactor: Double

    /// Angle (radians) of forearm raise — wrist rotating to face the user —
    /// above which we flag `wristRaiseMagnitude` toward 1.0 so the detector
    /// can reject "checking the watch" as a false squat.
    let wristRaiseFullAngle: Double

    init(
        fullDepthAngle: Double = 1.05,           // ~60°
        standingAngleTolerance: Double = 0.17,   // ~10°
        standingAccelerationTolerance: Double = 0.12,
        standingRotationTolerance: Double = 0.6,
        depthSmoothingFactor: Double = 0.35,
        baselineAdaptationFactor: Double = 0.05,
        wristRaiseFullAngle: Double = 1.4        // ~80°
    ) {
        self.fullDepthAngle = max(fullDepthAngle, 0.1)
        self.standingAngleTolerance = max(standingAngleTolerance, 0.0)
        self.standingAccelerationTolerance = max(standingAccelerationTolerance, 0.0)
        self.standingRotationTolerance = max(standingRotationTolerance, 0.0)
        self.depthSmoothingFactor = depthSmoothingFactor.clampedUnit()
        self.baselineAdaptationFactor = baselineAdaptationFactor.clampedUnit()
        self.wristRaiseFullAngle = max(wristRaiseFullAngle, 0.1)
    }
}

/// Converts a stream of `DeviceMotionSnapshot` readings into the
/// `SquatMotionSample` values consumed by `SquatDetectionManager`.
///
/// The core idea: while standing, the wrist's gravity vector points in a
/// stable "baseline" direction. As the user squats, the arm and torso tilt,
/// rotating that gravity vector away from baseline. The angular deviation,
/// normalized against `fullDepthAngle`, gives an estimate of squat depth that
/// is robust to the integration drift that plagues raw-acceleration
/// approaches.
///
/// This processor is deliberately free of any CoreMotion dependency so its
/// math can be exercised by deterministic unit tests.
final class SquatMotionSignalProcessor {
    private let config: SquatSignalProcessingConfig
    private var baselineGravity: MotionVector?
    private var smoothedDepth: Double = 0.0

    init(config: SquatSignalProcessingConfig = SquatSignalProcessingConfig()) {
        self.config = config
    }

    /// Discards calibration so the next quiet standing sample re-establishes
    /// the baseline. Call when a detection session starts.
    func reset() {
        baselineGravity = nil
        smoothedDepth = 0.0
    }

    /// Processes one motion snapshot and returns the derived squat sample,
    /// or `nil` until a standing baseline has been established.
    func process(_ snapshot: DeviceMotionSnapshot) -> SquatMotionSample? {
        guard let gravityDirection = snapshot.gravity.normalized() else {
            return nil
        }

        let accelerationMagnitude = snapshot.userAcceleration.magnitude
        let rotationMagnitude = snapshot.rotationRate.magnitude
        let isMechanicallyQuiet = accelerationMagnitude <= config.standingAccelerationTolerance
            && rotationMagnitude <= config.standingRotationTolerance

        guard let baseline = baselineGravity else {
            // First quiet sample establishes the standing baseline.
            if isMechanicallyQuiet {
                baselineGravity = gravityDirection
            }
            return nil
        }

        let deviationAngle = angleBetween(baseline, gravityDirection)
        let rawDepth = normalizedDepth(forDeviationAngle: deviationAngle)
        smoothedDepth += config.depthSmoothingFactor * (rawDepth - smoothedDepth)

        let isNearBaseline = deviationAngle <= config.standingAngleTolerance
        let isStandingStable = isNearBaseline && isMechanicallyQuiet

        // Re-calibrate slowly toward the current direction while genuinely
        // standing, absorbing posture drift without chasing squat motion.
        if isStandingStable {
            baselineGravity = slerpToward(
                from: baseline,
                to: gravityDirection,
                factor: config.baselineAdaptationFactor
            )
        }

        return SquatMotionSample(
            timestamp: snapshot.timestamp,
            normalizedDepth: smoothedDepth,
            wristRaiseMagnitude: wristRaiseMagnitude(for: snapshot, baseline: baseline),
            isStandingStable: isStandingStable
        )
    }

    // MARK: - Math

    private func normalizedDepth(forDeviationAngle angle: Double) -> Double {
        guard angle > config.standingAngleTolerance else { return 0.0 }
        let span = config.fullDepthAngle - config.standingAngleTolerance
        guard span > 0 else { return 1.0 }
        return ((angle - config.standingAngleTolerance) / span).clampedUnit()
    }

    /// Estimates how much the wrist is raised toward the face. A raised wrist
    /// rotates the device so gravity moves toward the device's +Y axis
    /// (CoreMotion convention: the screen-up axis). We approximate this with
    /// the component of the current gravity along the baseline-orthogonal
    /// "up" direction; large values indicate a raise rather than a squat.
    private func wristRaiseMagnitude(for snapshot: DeviceMotionSnapshot, baseline: MotionVector) -> Double {
        guard let gravityDirection = snapshot.gravity.normalized() else { return 0.0 }
        // Project onto the device's own Y axis: when checking the watch the
        // face tilts up and gravity's y-component grows positive.
        let raiseAngle = acos(max(min(gravityDirection.y, 1.0), -1.0))
        // raiseAngle ~ π when face fully up; map deviation from "neutral".
        let neutral = acos(max(min(baseline.y, 1.0), -1.0))
        let delta = abs(raiseAngle - neutral)
        return (delta / config.wristRaiseFullAngle).clampedUnit()
    }

    private func angleBetween(_ lhs: MotionVector, _ rhs: MotionVector) -> Double {
        let dot = max(min(lhs.dot(rhs), 1.0), -1.0)
        return acos(dot)
    }

    /// Spherical-ish interpolation between two unit vectors. For the tiny
    /// adaptation factors used here a normalized linear blend is sufficient
    /// and avoids trig in the hot path.
    private func slerpToward(from: MotionVector, to: MotionVector, factor: Double) -> MotionVector {
        let blended = MotionVector(
            x: from.x + factor * (to.x - from.x),
            y: from.y + factor * (to.y - from.y),
            z: from.z + factor * (to.z - from.z)
        )
        return blended.normalized() ?? from
    }
}

private extension Double {
    func clampedUnit() -> Double {
        min(max(self, 0.0), 1.0)
    }
}
