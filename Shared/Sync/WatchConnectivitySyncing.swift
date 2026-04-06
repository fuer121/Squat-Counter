import Foundation

protocol WatchConnectivitySyncing: Sendable {
    func send(payload: SyncPayload) async throws
}

enum SyncError: Error {
    case unavailable
}

final class NoopSyncCoordinator: WatchConnectivitySyncing {
    func send(payload: SyncPayload) async throws {
        throw SyncError.unavailable
    }
}

