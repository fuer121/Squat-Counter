import Foundation

/// A CoreMotion-free snapshot of a single device-motion reading.
///
/// This type intentionally does **not** import CoreMotion so the signal
/// pipeline that consumes it (`SquatMotionSignalProcessor`) can be unit
/// tested on any platform without a physical Apple Watch. The watch
/// extension is responsible for translating `CMDeviceMotion` into this
/// shape (see `CoreMotionSquatSampleProvider`).
///
/// Conventions:
/// - All vectors are expressed in the device reference frame.
/// - `gravity` and `userAcceleration` are in units of g (matching CoreMotion).
/// - `gravity` points toward the earth; CoreMotion already removes it from
///   `userAcceleration`.
/// - `rotationRate` is in radians per second.
struct DeviceMotionSnapshot: Equatable, Sendable {
    let timestamp: TimeInterval
    let gravity: MotionVector
    let userAcceleration: MotionVector
    let rotationRate: MotionVector

    init(
        timestamp: TimeInterval,
        gravity: MotionVector,
        userAcceleration: MotionVector,
        rotationRate: MotionVector = .zero
    ) {
        self.timestamp = timestamp
        self.gravity = gravity
        self.userAcceleration = userAcceleration
        self.rotationRate = rotationRate
    }
}

/// A minimal 3-component vector used by the motion pipeline.
struct MotionVector: Equatable, Sendable {
    var x: Double
    var y: Double
    var z: Double

    static let zero = MotionVector(x: 0, y: 0, z: 0)

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }

    func dot(_ other: MotionVector) -> Double {
        x * other.x + y * other.y + z * other.z
    }

    /// Returns a unit-length copy, or `nil` if the vector is effectively zero.
    func normalized() -> MotionVector? {
        let length = magnitude
        guard length > 1e-6 else { return nil }
        return MotionVector(x: x / length, y: y / length, z: z / length)
    }
}

/// Abstracts the source of raw device-motion snapshots so the detection
/// stack can be driven by a real `CMMotionManager` in production and by a
/// deterministic fake in tests.
protocol SquatMotionSampleProviding: AnyObject {
    var isRunning: Bool { get }

    /// Starts streaming motion snapshots on a regular cadence. The handler is
    /// always invoked on the main thread so downstream `@Published` mutations
    /// in the view model stay on the main actor.
    func start(handler: @escaping (DeviceMotionSnapshot) -> Void)

    func stop()
}

/// A no-op provider used as the default when no motion hardware is wired in
/// (e.g. on iOS, in unit tests, or in SwiftUI previews). It never emits
/// snapshots, so `.live` detection simply produces no automatic reps.
final class NoopSquatMotionSampleProvider: SquatMotionSampleProviding {
    private(set) var isRunning = false

    func start(handler: @escaping (DeviceMotionSnapshot) -> Void) {
        isRunning = true
    }

    func stop() {
        isRunning = false
    }
}
