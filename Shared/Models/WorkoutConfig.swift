import Foundation

struct WorkoutConfig: Codable, Equatable, Sendable {
    static let defaultRepsPerSet = 15
    static let defaultTotalSets = 3
    static let defaultRestSeconds = 30
    static let countdownSeconds = 3

    static let repsRange = 5...50
    static let setsRange = 1...10
    static let restRange = 15...120

    var repsPerSet: Int
    var totalSets: Int
    var restSeconds: Int
    var countdownSeconds: Int
    var tempoCueEnabled: Bool

    init(
        repsPerSet: Int = WorkoutConfig.defaultRepsPerSet,
        totalSets: Int = WorkoutConfig.defaultTotalSets,
        restSeconds: Int = WorkoutConfig.defaultRestSeconds,
        countdownSeconds: Int = WorkoutConfig.countdownSeconds,
        tempoCueEnabled: Bool = true
    ) {
        self.repsPerSet = WorkoutConfig.repsRange.clamp(repsPerSet)
        self.totalSets = WorkoutConfig.setsRange.clamp(totalSets)
        self.restSeconds = WorkoutConfig.restRange.clamp(restSeconds)
        self.countdownSeconds = countdownSeconds
        self.tempoCueEnabled = tempoCueEnabled
    }
}

private extension ClosedRange where Bound == Int {
    func clamp(_ value: Int) -> Int {
        Swift.min(Swift.max(lowerBound, value), upperBound)
    }
}
