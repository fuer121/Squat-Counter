import Foundation

enum SquatDetectionEvent: Codable, Equatable, Sendable {
    case repDetected
    case motionStateChanged(SquatMotionState)
}

