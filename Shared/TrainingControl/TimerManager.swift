import Foundation

protocol TimerManaging: AnyObject {
    var activeContext: TrainingTimerContext? { get }
    var isPaused: Bool { get }

    func start(_ context: TrainingTimerContext, handler: @escaping (TrainingTimerEvent) -> Void)
    func pause()
    func resume()
    func cancel()
}

protocol TimerCancellation: AnyObject {
    func cancel()
}

protocol TimerScheduling {
    @discardableResult
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> TimerCancellation
}

final class TimerManager: TimerManaging {
    private let scheduler: TimerScheduling
    private var scheduledTimer: TimerCancellation?
    private var eventHandler: ((TrainingTimerEvent) -> Void)?
    private var remainingSeconds: Int?
    private var tempoInterval: TimeInterval?

    private(set) var activeContext: TrainingTimerContext?
    private(set) var isPaused = false

    init(scheduler: TimerScheduling = FoundationTimerScheduler()) {
        self.scheduler = scheduler
    }

    func start(_ context: TrainingTimerContext, handler: @escaping (TrainingTimerEvent) -> Void) {
        cancel()
        activeContext = context
        eventHandler = handler
        isPaused = false

        switch context {
        case .countdown(let durationSeconds):
            remainingSeconds = durationSeconds
            if durationSeconds > 0 {
                eventHandler?(.countdownTick(remainingSeconds: durationSeconds))
            }
            scheduleNextTick()
        case .rest(let durationSeconds):
            remainingSeconds = durationSeconds
            scheduleNextTick()
        case .tempo(let interval):
            tempoInterval = interval
            scheduleNextTick()
        }
    }

    func pause() {
        guard activeContext != nil, isPaused == false else { return }
        isPaused = true
        scheduledTimer?.cancel()
        scheduledTimer = nil
    }

    func resume() {
        guard activeContext != nil, isPaused else { return }
        isPaused = false
        scheduleNextTick()
    }

    func cancel() {
        scheduledTimer?.cancel()
        scheduledTimer = nil
        activeContext = nil
        remainingSeconds = nil
        tempoInterval = nil
        eventHandler = nil
        isPaused = false
    }

    private func scheduleNextTick() {
        guard isPaused == false, let activeContext else { return }

        switch activeContext {
        case .countdown:
            schedule(after: 1.0, action: handleCountdownTick)
        case .rest:
            schedule(after: 1.0, action: handleRestTick)
        case .tempo(let interval):
            let delay = tempoInterval ?? interval
            schedule(after: delay, action: handleTempoCue)
        }
    }

    private func schedule(after delay: TimeInterval, action: @escaping () -> Void) {
        scheduledTimer?.cancel()
        scheduledTimer = scheduler.schedule(after: delay, action: action)
    }

    private func handleCountdownTick() {
        guard case .countdown = activeContext, let remainingSeconds else { return }

        let nextRemaining = remainingSeconds - 1
        self.remainingSeconds = nextRemaining

        if nextRemaining > 0 {
            eventHandler?(.countdownTick(remainingSeconds: nextRemaining))
            scheduleNextTick()
            return
        }

        finishActiveContext(with: .countdownCompleted)
    }

    private func handleRestTick() {
        guard case .rest = activeContext, let remainingSeconds else { return }

        let nextRemaining = remainingSeconds - 1
        self.remainingSeconds = nextRemaining

        if nextRemaining > 0 {
            eventHandler?(.restTick(remainingSeconds: nextRemaining))
            scheduleNextTick()
            return
        }

        finishActiveContext(with: .restCompleted)
    }

    private func handleTempoCue() {
        guard case .tempo = activeContext else { return }
        eventHandler?(.tempoCue)
        scheduleNextTick()
    }

    private func finishActiveContext(with event: TrainingTimerEvent) {
        scheduledTimer?.cancel()
        scheduledTimer = nil
        activeContext = nil
        remainingSeconds = nil
        tempoInterval = nil
        eventHandler?(event)
    }
}

final class FoundationTimerScheduler: TimerScheduling {
    @discardableResult
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> TimerCancellation {
        let target = FoundationTimerTarget(action: action)
        let timer = Timer(timeInterval: delay, target: target, selector: #selector(FoundationTimerTarget.fire), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        return FoundationTimerToken(timer: timer, target: target)
    }
}

final class FoundationTimerToken: TimerCancellation {
    private let timer: Timer
    private let target: FoundationTimerTarget

    init(timer: Timer, target: FoundationTimerTarget) {
        self.timer = timer
        self.target = target
    }

    func cancel() {
        timer.invalidate()
    }
}

final class FoundationTimerTarget: NSObject {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    @objc
    func fire() {
        action()
    }
}
