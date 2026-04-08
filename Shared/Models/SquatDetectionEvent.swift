import Foundation

enum SquatDetectionEvent: Codable, Equatable, Sendable {
    case repDetected
    case motionStateChanged(SquatMotionState)
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
        descendingThreshold: Double = 0.32,
        bottomThreshold: Double = 0.68,
        ascendingThreshold: Double = 0.42,
        standingThreshold: Double = 0.12,
        standingStabilityDuration: TimeInterval = 0.35,
        cooldownDuration: TimeInterval = 0.8,
        maximumWristRaiseMagnitude: Double = 0.45
    ) {
        let clampedStanding = standingThreshold.clamped(to: 0.0...0.25)
        let clampedDescending = max(descendingThreshold.clamped(to: 0.15...0.75), clampedStanding + 0.05)
        let clampedBottom = max(bottomThreshold.clamped(to: 0.3...1.0), clampedDescending + 0.1)
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
}

final class SquatDetectionManager: SquatDetectionManaging {
    private let now: () -> TimeInterval
    private var eventHandler: ((SquatDetectionEvent) -> Void)?
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
            return
        }

        if sample.wristRaiseMagnitude > thresholds.maximumWristRaiseMagnitude,
           sample.normalizedDepth < thresholds.bottomThreshold {
            resetToStanding()
            standingStableSince = nil
            return
        }

        switch currentMotionState {
        case .standing:
            let canBeginDescending = hasStableStanding(at: sample.timestamp)

            if canBeginDescending, sample.normalizedDepth >= thresholds.descendingThreshold {
                standingStableSince = nil
                transition(to: .descending)
                return
            }

            updateStandingBaseline(with: sample)
        case .descending:
            if sample.normalizedDepth >= thresholds.bottomThreshold {
                transition(to: .bottom)
            } else if sample.normalizedDepth <= thresholds.standingThreshold {
                resetToStanding()
                updateStandingBaseline(with: sample)
            }
        case .bottom:
            if sample.normalizedDepth <= thresholds.ascendingThreshold {
                transition(to: .ascending)
            }
        case .ascending:
            if sample.normalizedDepth <= thresholds.standingThreshold {
                completeRep(at: sample.timestamp)
                updateStandingBaseline(with: sample)
            } else if sample.normalizedDepth >= thresholds.bottomThreshold {
                transition(to: .bottom)
            }
        case .repCompleted:
            resetToStanding()
            updateStandingBaseline(with: sample)
        }
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
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
