import Foundation

enum TrainingTimerContext: Equatable, Sendable {
    case countdown(durationSeconds: Int)
    case rest(durationSeconds: Int)
    case tempo(interval: TimeInterval)
}

enum TrainingTimerEvent: Equatable, Sendable {
    case countdownTick(remainingSeconds: Int)
    case countdownCompleted
    case restTick(remainingSeconds: Int)
    case restCompleted
    case tempoCue
}

enum TrainingHapticEvent: Equatable, Sendable {
    case countdownTick(remainingSeconds: Int)
    case countdownCompleted
    case repCompleted
    case setCompleted
    case nextSetStarted
    case workoutCompleted
    case tempoCue
}

enum TrainingHapticPattern: Equatable, Sendable {
    case light
    case medium
    case strong
}
