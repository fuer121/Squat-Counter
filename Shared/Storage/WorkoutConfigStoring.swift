import Foundation

protocol WorkoutConfigStoring {
    func loadConfig() -> WorkoutConfig
    func saveConfig(_ config: WorkoutConfig)
}

final class UserDefaultsWorkoutConfigStore: WorkoutConfigStoring {
    private enum Keys {
        static let workoutConfig = "workoutConfig"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadConfig() -> WorkoutConfig {
        guard
            let data = defaults.data(forKey: Keys.workoutConfig),
            let config = try? decoder.decode(WorkoutConfig.self, from: data)
        else {
            return WorkoutConfig()
        }

        return config
    }

    func saveConfig(_ config: WorkoutConfig) {
        guard let data = try? encoder.encode(config) else {
            return
        }

        defaults.set(data, forKey: Keys.workoutConfig)
    }
}
