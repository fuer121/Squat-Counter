import Foundation
import HealthKit

@MainActor
final class WatchWorkoutHealthManager: NSObject, WorkoutHealthManaging {
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    func prepareForWorkout(at startDate: Date) async -> WorkoutHealthSessionStartResult {
        guard HKHealthStore.isHealthDataAvailable() else {
            clearWorkoutState()
            return .skipped(.unavailable)
        }

        if workoutSession != nil, workoutBuilder != nil {
            return .started
        }

        let authorizationStatus = await resolveAuthorizationStatus()
        guard authorizationStatus == .sharingAuthorized else {
            clearWorkoutState()
            return .skipped(authorizationStatus)
        }

        do {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .functionalStrengthTraining
            configuration.locationType = .indoor

            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

            workoutSession = session
            workoutBuilder = builder

            session.startActivity(with: startDate)
            try await beginCollection(on: builder, startDate: startDate)
            return .started
        } catch {
            clearWorkoutState()
            return .failed
        }
    }

    func pauseWorkout() async {
        workoutSession?.pause()
    }

    func resumeWorkout() async {
        workoutSession?.resume()
    }

    func finishWorkout(summary: WorkoutSummary, endDate: Date) async -> WorkoutHealthSaveResult {
        guard HKHealthStore.isHealthDataAvailable() else {
            clearWorkoutState()
            return .skipped(.unavailable)
        }

        guard let session = workoutSession, let builder = workoutBuilder else {
            return .skipped(await currentAuthorizationStatus())
        }

        do {
            session.end()
            try await addMetadata(summary.metadata, to: builder)
            try await endCollection(on: builder, endDate: endDate)
            _ = try await finishWorkout(on: builder)
            clearWorkoutState()
            return .saved
        } catch {
            clearWorkoutState()
            return .failed
        }
    }

    func discardWorkout() async {
        workoutSession?.end()
        workoutBuilder?.discardWorkout()
        clearWorkoutState()
    }

    private func resolveAuthorizationStatus() async -> WorkoutHealthAuthorizationStatus {
        let currentStatus = await currentAuthorizationStatus()
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        do {
            try await requestAuthorization()
            return await currentAuthorizationStatus()
        } catch {
            return .failedAuthorizationFallback
        }
    }

    private func currentAuthorizationStatus() async -> WorkoutHealthAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }

        return WorkoutHealthAuthorizationStatus(
            hkStatus: healthStore.authorizationStatus(for: HKObjectType.workoutType())
        )
    }

    private func requestAuthorization() async throws {
        let workoutType = HKObjectType.workoutType()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [workoutType], read: []) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func beginCollection(on builder: HKLiveWorkoutBuilder, startDate: Date) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.beginCollection(withStart: startDate) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: WorkoutHealthManagerError.beginCollectionFailed)
                }
            }
        }
    }

    private func addMetadata(_ metadata: [String: Any], to builder: HKLiveWorkoutBuilder) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.addMetadata(metadata) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: WorkoutHealthManagerError.metadataFailed)
                }
            }
        }
    }

    private func endCollection(on builder: HKLiveWorkoutBuilder, endDate: Date) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.endCollection(withEnd: endDate) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: WorkoutHealthManagerError.endCollectionFailed)
                }
            }
        }
    }

    private func finishWorkout(on builder: HKLiveWorkoutBuilder) async throws -> HKWorkout {
        try await withCheckedThrowingContinuation { continuation in
            builder.finishWorkout { workout, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let workout {
                    continuation.resume(returning: workout)
                } else {
                    continuation.resume(throwing: WorkoutHealthManagerError.finishWorkoutFailed)
                }
            }
        }
    }

    private func clearWorkoutState() {
        workoutSession = nil
        workoutBuilder = nil
    }
}

private extension WorkoutHealthAuthorizationStatus {
    init(hkStatus: HKAuthorizationStatus) {
        switch hkStatus {
        case .notDetermined:
            self = .notDetermined
        case .sharingAuthorized:
            self = .sharingAuthorized
        case .sharingDenied:
            self = .sharingDenied
        @unknown default:
            self = .unavailable
        }
    }

    static var failedAuthorizationFallback: WorkoutHealthAuthorizationStatus {
        .sharingDenied
    }
}

private extension WorkoutSummary {
    var metadata: [String: Any] {
        [
            "com.fuer.squatcounter.totalSets": totalSets,
            "com.fuer.squatcounter.totalReps": totalReps
        ]
    }
}

private enum WorkoutHealthManagerError: Error {
    case beginCollectionFailed
    case metadataFailed
    case endCollectionFailed
    case finishWorkoutFailed
}
