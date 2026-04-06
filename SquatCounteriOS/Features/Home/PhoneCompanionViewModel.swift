import Foundation

@MainActor
final class PhoneCompanionViewModel: ObservableObject {
    @Published private(set) var config: WorkoutConfig
    @Published private(set) var summaries: [WorkoutSummary]

    private let store: WorkoutConfigStoring

    init(store: WorkoutConfigStoring = UserDefaultsWorkoutConfigStore()) {
        self.store = store
        self.config = store.loadConfig()
        self.summaries = []
    }

    func updateReps(_ reps: Int) {
        config.repsPerSet = WorkoutConfig.repsRange.clamp(reps)
        persist()
    }

    func updateSets(_ sets: Int) {
        config.totalSets = WorkoutConfig.setsRange.clamp(sets)
        persist()
    }

    func updateRest(_ seconds: Int) {
        config.restSeconds = WorkoutConfig.restRange.clamp(seconds)
        persist()
    }

    private func persist() {
        store.saveConfig(config)
    }
}

private extension ClosedRange where Bound == Int {
    func clamp(_ value: Int) -> Int {
        Swift.min(Swift.max(lowerBound, value), upperBound)
    }
}
