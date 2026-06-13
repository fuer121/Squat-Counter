import Foundation
import CoreMotion

/// Bridges CoreMotion's `CMMotionManager` device-motion stream into the
/// CoreMotion-free `DeviceMotionSnapshot` values the detection pipeline
/// consumes. This is the only place in the codebase that touches CoreMotion,
/// keeping the rest of the stack (signal processing, rep detection) testable
/// on any platform.
///
/// Lifecycle: `start` begins device-motion updates at a fixed cadence and
/// forwards each reading on the main thread; `stop` halts updates and clears
/// the handler. Safe to start/stop repeatedly across training sets.
final class CoreMotionSquatSampleProvider: SquatMotionSampleProviding {
    private let motionManager: CMMotionManager
    private let updateInterval: TimeInterval
    private let operationQueue: OperationQueue
    private var handler: ((DeviceMotionSnapshot) -> Void)?

    private(set) var isRunning = false

    /// - Parameters:
    ///   - motionManager: Injectable for testing; defaults to a fresh manager.
    ///   - sampleRate: Samples per second. 50 Hz is a good balance between
    ///     responsiveness and battery on Apple Watch; device-motion fusion is
    ///     comfortably available at this rate.
    init(
        motionManager: CMMotionManager = CMMotionManager(),
        sampleRate: Double = 50.0
    ) {
        self.motionManager = motionManager
        self.updateInterval = 1.0 / max(sampleRate, 1.0)

        let queue = OperationQueue()
        queue.name = "com.fuer.squatcounter.motion"
        queue.maxConcurrentOperationCount = 1
        self.operationQueue = queue
    }

    func start(handler: @escaping (DeviceMotionSnapshot) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            isRunning = false
            return
        }

        self.handler = handler
        isRunning = true

        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motion, _ in
            guard let self, let motion else { return }

            let snapshot = DeviceMotionSnapshot(
                timestamp: motion.timestamp,
                gravity: MotionVector(
                    x: motion.gravity.x,
                    y: motion.gravity.y,
                    z: motion.gravity.z
                ),
                userAcceleration: MotionVector(
                    x: motion.userAcceleration.x,
                    y: motion.userAcceleration.y,
                    z: motion.userAcceleration.z
                ),
                rotationRate: MotionVector(
                    x: motion.rotationRate.x,
                    y: motion.rotationRate.y,
                    z: motion.rotationRate.z
                )
            )

            // Hop to the main thread so downstream @Published mutations in the
            // view model stay on the main actor.
            DispatchQueue.main.async {
                self.handler?(snapshot)
            }
        }
    }

    func stop() {
        isRunning = false
        handler = nil

        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
}
