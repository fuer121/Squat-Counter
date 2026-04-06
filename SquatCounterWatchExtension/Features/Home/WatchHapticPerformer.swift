import WatchKit

final class WatchHapticPerformer: HapticPerforming {
    func perform(_ pattern: TrainingHapticPattern) {
        WKInterfaceDevice.current().play(mappedType(for: pattern))
    }

    private func mappedType(for pattern: TrainingHapticPattern) -> WKHapticType {
        switch pattern {
        case .light:
            return .click
        case .medium:
            return .directionUp
        case .strong:
            return .success
        }
    }
}
