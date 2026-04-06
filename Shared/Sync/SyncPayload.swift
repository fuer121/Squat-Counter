import Foundation

struct SyncPayload: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        case config
        case workoutSummary
        case watchStateSnapshot
    }

    var kind: Kind
    var updatedAt: Date
    var config: WorkoutConfig?
    var summary: WorkoutSummary?
    var snapshot: WatchStateSnapshot?

    static func config(_ config: WorkoutConfig, updatedAt: Date = .now) -> SyncPayload {
        SyncPayload(kind: .config, updatedAt: updatedAt, config: config, summary: nil, snapshot: nil)
    }

    static func workoutSummary(_ summary: WorkoutSummary, updatedAt: Date = .now) -> SyncPayload {
        SyncPayload(kind: .workoutSummary, updatedAt: updatedAt, config: nil, summary: summary, snapshot: nil)
    }

    static func snapshot(_ snapshot: WatchStateSnapshot, updatedAt: Date = .now) -> SyncPayload {
        SyncPayload(kind: .watchStateSnapshot, updatedAt: updatedAt, config: nil, summary: nil, snapshot: snapshot)
    }
}

struct WorkoutSummary: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var completedAt: Date
    var totalSets: Int
    var totalReps: Int
    var durationSeconds: Int

    init(
        id: UUID = UUID(),
        completedAt: Date = .now,
        totalSets: Int,
        totalReps: Int,
        durationSeconds: Int
    ) {
        self.id = id
        self.completedAt = completedAt
        self.totalSets = totalSets
        self.totalReps = totalReps
        self.durationSeconds = durationSeconds
    }
}

struct WatchStateSnapshot: Codable, Equatable, Sendable {
    var state: WorkoutState
    var progress: WorkoutProgress
}

