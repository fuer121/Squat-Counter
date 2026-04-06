import Foundation

protocol HapticManaging: AnyObject {
    @discardableResult
    func play(_ event: TrainingHapticEvent) -> TrainingHapticEvent?

    @discardableResult
    func playHighestPriority(among events: [TrainingHapticEvent]) -> TrainingHapticEvent?
}

protocol HapticPerforming: AnyObject {
    func perform(_ pattern: TrainingHapticPattern)
}

final class HapticManager: HapticManaging {
    private let performer: HapticPerforming

    init(performer: HapticPerforming = NoOpHapticPerformer()) {
        self.performer = performer
    }

    @discardableResult
    func play(_ event: TrainingHapticEvent) -> TrainingHapticEvent? {
        playHighestPriority(among: [event])
    }

    @discardableResult
    func playHighestPriority(among events: [TrainingHapticEvent]) -> TrainingHapticEvent? {
        guard let event = highestPriorityEvent(in: events) else { return nil }
        performer.perform(pattern(for: event))
        return event
    }

    func highestPriorityEvent(in events: [TrainingHapticEvent]) -> TrainingHapticEvent? {
        events.max { left, right in
            priority(for: left) < priority(for: right)
        }
    }

    func pattern(for event: TrainingHapticEvent) -> TrainingHapticPattern {
        switch event {
        case .countdownTick, .countdownCompleted, .repCompleted, .tempoCue:
            return .light
        case .setCompleted, .nextSetStarted:
            return .medium
        case .workoutCompleted:
            return .strong
        }
    }

    private func priority(for event: TrainingHapticEvent) -> Int {
        switch event {
        case .workoutCompleted:
            return 4
        case .setCompleted, .nextSetStarted:
            return 3
        case .repCompleted:
            return 2
        case .countdownTick, .countdownCompleted:
            return 1
        case .tempoCue:
            return 0
        }
    }
}

final class NoOpHapticPerformer: HapticPerforming {
    func perform(_ pattern: TrainingHapticPattern) {}
}
