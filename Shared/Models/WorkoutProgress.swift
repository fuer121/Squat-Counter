import Foundation

struct WorkoutProgress: Codable, Equatable, Sendable {
    var currentSet: Int
    var currentRep: Int
    var totalCompletedReps: Int
    var remainingRestSeconds: Int

    static let empty = WorkoutProgress(
        currentSet: 1,
        currentRep: 0,
        totalCompletedReps: 0,
        remainingRestSeconds: 0
    )
}

