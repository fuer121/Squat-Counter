import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

protocol WatchConnectivitySyncing: Sendable {
    func send(payload: SyncPayload) async throws
}

enum SyncError: Error {
    case unavailable
    case payloadEncodingFailed
}

enum SyncPayloadNotification {
    static let didReceive = Notification.Name("SyncPayload.didReceive")

    private static let payloadKey = "payload"

    static func post(_ payload: SyncPayload, notificationCenter: NotificationCenter = .default) {
        notificationCenter.post(
            name: didReceive,
            object: nil,
            userInfo: [payloadKey: payload]
        )
    }

    static func payload(from notification: Notification) -> SyncPayload? {
        notification.userInfo?[payloadKey] as? SyncPayload
    }
}

final class NoopSyncCoordinator: WatchConnectivitySyncing, @unchecked Sendable {
    func send(payload: SyncPayload) async throws {
        throw SyncError.unavailable
    }
}

#if canImport(WatchConnectivity)
private protocol WatchConnectivitySessioning: AnyObject {
    var delegate: WCSessionDelegate? { get set }
    func activate()
    func updateApplicationContext(_ applicationContext: [String: Any]) throws
    @discardableResult
    func transferUserInfo(_ userInfo: [String: Any]) -> WCSessionUserInfoTransfer
}

extension WCSession: WatchConnectivitySessioning {}

final class WatchConnectivitySyncCoordinator: NSObject, WatchConnectivitySyncing, @unchecked Sendable {
    static let shared = WatchConnectivitySyncCoordinator()

    private enum PayloadEnvelope {
        static let dataKey = "syncPayloadData"
    }

    private let notificationCenter: NotificationCenter
    private let session: WatchConnectivitySessioning?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init(
        session: WatchConnectivitySessioning? = WCSession.isSupported() ? WCSession.default : nil,
        notificationCenter: NotificationCenter = .default
    ) {
        self.session = session
        self.notificationCenter = notificationCenter
        super.init()

        self.session?.delegate = self
        self.session?.activate()
    }

    func send(payload: SyncPayload) async throws {
        guard let session else {
            throw SyncError.unavailable
        }

        guard let data = try? encoder.encode(payload) else {
            throw SyncError.payloadEncodingFailed
        }

        let envelope: [String: Any] = [PayloadEnvelope.dataKey: data]

        switch payload.kind {
        case .config, .watchStateSnapshot:
            try session.updateApplicationContext(envelope)
        case .workoutSummary:
            session.transferUserInfo(envelope)
        }
    }

    private func handleIncomingEnvelope(_ envelope: [String: Any]) {
        guard
            let data = envelope[PayloadEnvelope.dataKey] as? Data,
            let payload = try? decoder.decode(SyncPayload.self, from: data)
        else {
            return
        }

        SyncPayloadNotification.post(payload, notificationCenter: notificationCenter)
    }
}

extension WatchConnectivitySyncCoordinator: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleIncomingEnvelope(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleIncomingEnvelope(userInfo)
    }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
}
#else
final class WatchConnectivitySyncCoordinator: WatchConnectivitySyncing, @unchecked Sendable {
    static let shared = WatchConnectivitySyncCoordinator()

    func send(payload: SyncPayload) async throws {
        throw SyncError.unavailable
    }
}
#endif
