import XCTest

final class SquatMotionSignalProcessorTests: XCTestCase {
    // Gravity pointing straight "down" the device -Z axis is our standing
    // baseline in these tests. Tilting toward -Y simulates the wrist/arm
    // rotating as the body descends into a squat.
    private let standingGravity = MotionVector(x: 0, y: 0, z: -1)

    func testReturnsNilUntilQuietStandingBaselineEstablished() {
        let processor = SquatMotionSignalProcessor()

        // A noisy first sample cannot anchor the baseline.
        let noisy = DeviceMotionSnapshot(
            timestamp: 0,
            gravity: standingGravity,
            userAcceleration: MotionVector(x: 0.5, y: 0.5, z: 0.5),
            rotationRate: MotionVector(x: 2, y: 0, z: 0)
        )
        XCTAssertNil(processor.process(noisy))

        // A quiet sample establishes the baseline but still returns nil that tick.
        let quiet = DeviceMotionSnapshot(
            timestamp: 0.1,
            gravity: standingGravity,
            userAcceleration: .zero
        )
        XCTAssertNil(processor.process(quiet))

        // Subsequent quiet standing samples report ~zero depth and stability.
        let nextQuiet = DeviceMotionSnapshot(
            timestamp: 0.2,
            gravity: standingGravity,
            userAcceleration: .zero
        )
        let sample = processor.process(nextQuiet)
        XCTAssertNotNil(sample)
        XCTAssertEqual(sample?.normalizedDepth ?? 1, 0, accuracy: 0.001)
        XCTAssertTrue(sample?.isStandingStable ?? false)
    }

    func testDeepTiltDrivesDepthTowardOneOverTime() {
        let config = SquatSignalProcessingConfig(depthSmoothingFactor: 1.0) // no smoothing lag
        let processor = SquatMotionSignalProcessor(config: config)

        // Establish baseline (two quiet samples).
        _ = processor.process(quietStanding(at: 0))
        _ = processor.process(quietStanding(at: 0.1))

        // Tilt ~60° from baseline (full depth angle default is ~60°).
        let tilted = DeviceMotionSnapshot(
            timestamp: 0.2,
            gravity: MotionVector(x: 0, y: -sin(1.05), z: -cos(1.05)),
            userAcceleration: .zero
        )
        let sample = processor.process(tilted)
        XCTAssertNotNil(sample)
        XCTAssertGreaterThan(sample?.normalizedDepth ?? 0, 0.9)
        XCTAssertFalse(sample?.isStandingStable ?? true)
    }

    func testSmoothingDampsSuddenDepthSpike() {
        let config = SquatSignalProcessingConfig(depthSmoothingFactor: 0.3)
        let processor = SquatMotionSignalProcessor(config: config)

        _ = processor.process(quietStanding(at: 0))
        _ = processor.process(quietStanding(at: 0.1))

        let tilted = DeviceMotionSnapshot(
            timestamp: 0.2,
            gravity: MotionVector(x: 0, y: -sin(1.05), z: -cos(1.05)),
            userAcceleration: .zero
        )
        let sample = processor.process(tilted)
        // With a 0.3 factor a single spike to ~1.0 should land near 0.3, well
        // below the un-smoothed value — proving the EMA is applied.
        XCTAssertLessThan(sample?.normalizedDepth ?? 1, 0.5)
    }

    func testResetClearsBaselineAndDepth() {
        let processor = SquatMotionSignalProcessor()
        _ = processor.process(quietStanding(at: 0))
        _ = processor.process(quietStanding(at: 0.1))

        processor.reset()

        // After reset the next sample is treated as a fresh baseline (nil).
        XCTAssertNil(processor.process(quietStanding(at: 0.2)))
    }

    private func quietStanding(at timestamp: TimeInterval) -> DeviceMotionSnapshot {
        DeviceMotionSnapshot(
            timestamp: timestamp,
            gravity: standingGravity,
            userAcceleration: .zero
        )
    }
}

/// Drives the full live pipeline: a fake provider streams snapshots that the
/// detection manager feeds through the real signal processor and rep state
/// machine. Verifies a synthesized squat produces exactly one `repDetected`.
final class LiveDetectionPipelineTests: XCTestCase {
    func testSynthesizedSquatProducesExactlyOneRep() {
        let provider = FakeMotionSampleProvider()
        // Generous depth/standing tolerances so the synthesized trajectory
        // crosses the detector thresholds deterministically.
        let manager = SquatDetectionManager(
            thresholds: SquatDetectionThresholds(
                descendingThreshold: 0.3,
                bottomThreshold: 0.7,
                ascendingThreshold: 0.45,
                standingThreshold: 0.12,
                standingStabilityDuration: 0.1,
                cooldownDuration: 0.8
            ),
            sampleProvider: provider,
            signalProcessor: SquatMotionSignalProcessor(
                config: SquatSignalProcessingConfig(depthSmoothingFactor: 1.0)
            )
        )

        var events: [SquatDetectionEvent] = []
        manager.start(mode: .live) { events.append($0) }
        XCTAssertTrue(provider.isRunning)

        // Stand quietly to establish baseline + stable-standing duration.
        provider.emit(standing(at: 0.0))
        provider.emit(standing(at: 0.15))
        provider.emit(standing(at: 0.3))
        // Descend → bottom → ascend → stand.
        provider.emit(tilt(angle: 0.6, at: 0.45))  // descending
        provider.emit(tilt(angle: 1.1, at: 0.6))   // bottom
        provider.emit(tilt(angle: 0.5, at: 0.75))  // ascending
        provider.emit(standing(at: 0.9))           // back to standing → rep

        XCTAssertEqual(events.filter { $0 == .repDetected }.count, 1)

        manager.stop()
        XCTAssertFalse(provider.isRunning)
    }

    private let baseline = MotionVector(x: 0, y: 0, z: -1)

    private func standing(at t: TimeInterval) -> DeviceMotionSnapshot {
        DeviceMotionSnapshot(timestamp: t, gravity: baseline, userAcceleration: .zero)
    }

    private func tilt(angle: Double, at t: TimeInterval) -> DeviceMotionSnapshot {
        DeviceMotionSnapshot(
            timestamp: t,
            gravity: MotionVector(x: 0, y: -sin(angle), z: -cos(angle)),
            userAcceleration: .zero
        )
    }
}

private final class FakeMotionSampleProvider: SquatMotionSampleProviding {
    private(set) var isRunning = false
    private var handler: ((DeviceMotionSnapshot) -> Void)?

    func start(handler: @escaping (DeviceMotionSnapshot) -> Void) {
        isRunning = true
        self.handler = handler
    }

    func stop() {
        isRunning = false
        handler = nil
    }

    func emit(_ snapshot: DeviceMotionSnapshot) {
        handler?(snapshot)
    }
}
