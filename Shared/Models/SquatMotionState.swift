import Foundation

enum SquatMotionState: String, Codable, CaseIterable, Sendable {
    case standing
    case descending
    case bottom
    case ascending
    case repCompleted
}

