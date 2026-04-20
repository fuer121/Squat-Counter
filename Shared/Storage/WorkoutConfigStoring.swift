import Foundation

protocol WorkoutConfigStoring {
    func loadConfig() -> WorkoutConfig
    func saveConfig(_ config: WorkoutConfig)
}

protocol SquatCalibrationStoring {
    func loadCalibrationProfile() -> SquatCalibrationProfile?
    func saveCalibrationProfile(_ profile: SquatCalibrationProfile)
    func clearCalibrationProfile()
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

final class UserDefaultsSquatCalibrationStore: SquatCalibrationStoring {
    private enum Keys {
        static let calibrationProfile = "squatCalibrationProfile"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadCalibrationProfile() -> SquatCalibrationProfile? {
        guard
            let data = defaults.data(forKey: Keys.calibrationProfile),
            let profile = try? decoder.decode(SquatCalibrationProfile.self, from: data)
        else {
            return nil
        }

        return profile
    }

    func saveCalibrationProfile(_ profile: SquatCalibrationProfile) {
        guard let data = try? encoder.encode(profile) else {
            return
        }

        defaults.set(data, forKey: Keys.calibrationProfile)
    }

    func clearCalibrationProfile() {
        defaults.removeObject(forKey: Keys.calibrationProfile)
    }
}
