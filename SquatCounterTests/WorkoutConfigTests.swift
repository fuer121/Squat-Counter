import XCTest

final class WorkoutConfigTests: XCTestCase {
    func testDefaultValuesMatchProductDecision() {
        let config = WorkoutConfig()

        XCTAssertEqual(config.repsPerSet, 15)
        XCTAssertEqual(config.totalSets, 3)
        XCTAssertEqual(config.restSeconds, 30)
        XCTAssertEqual(config.countdownSeconds, 3)
        XCTAssertTrue(config.tempoCueEnabled)
    }

    func testConfigClampsValuesIntoSupportedRange() {
        let config = WorkoutConfig(repsPerSet: 100, totalSets: 0, restSeconds: 999)

        XCTAssertEqual(config.repsPerSet, 50)
        XCTAssertEqual(config.totalSets, 1)
        XCTAssertEqual(config.restSeconds, 120)
    }
}

final class WorkoutSessionViewModelTests: XCTestCase {
    func testStartCountdownCancelsAndCompletesAutomatically() {
        let scheduler = TestTimerScheduler()
        let timerManager = TimerManager(scheduler: scheduler)
        let hapticManager = HapticManagerSpy()
        let viewModel = WorkoutSessionViewModel(
            timerManager: timerManager,
            hapticManager: hapticManager,
            tempoCueInterval: 2.0
        )

        viewModel.startWorkout()
        XCTAssertEqual(viewModel.state, .countdown)
        XCTAssertEqual(viewModel.countdownRemainingSeconds, 3)
        XCTAssertEqual(hapticManager.playedEvents, [.countdownTick(remainingSeconds: 3)])

        viewModel.cancelCountdown()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.progress, .empty)
        XCTAssertEqual(viewModel.countdownRemainingSeconds, 0)

        viewModel.startWorkout()
        scheduler.advance(by: 1)
        XCTAssertEqual(viewModel.countdownRemainingSeconds, 2)

        scheduler.advance(by: 2)

        XCTAssertEqual(viewModel.state, .training)
        XCTAssertEqual(viewModel.progress.currentSet, 1)
        XCTAssertEqual(viewModel.progress.currentRep, 0)
    }

    func testPauseAndResumeFromTrainingStopsAndRestartsTempo() {
        let scheduler = TestTimerScheduler()
        let timerManager = TimerManager(scheduler: scheduler)
        let hapticManager = HapticManagerSpy()
        let viewModel = makeTrainingViewModel(timerManager: timerManager, hapticManager: hapticManager, scheduler: scheduler)

        scheduler.advance(by: 2)
        XCTAssertEqual(hapticManager.playedPriorityGroups.last, [.tempoCue])

        viewModel.pauseWorkout()
        XCTAssertEqual(viewModel.state, .paused)
        XCTAssertEqual(viewModel.pauseContext?.resumeTarget, .training)

        scheduler.advance(by: 4)
        XCTAssertEqual(hapticManager.playedPriorityGroups.filter { $0 == [.tempoCue] }.count, 1)

        viewModel.resumeWorkout()
        XCTAssertEqual(viewModel.state, .training)
        XCTAssertNil(viewModel.pauseContext)

        scheduler.advance(by: 2)
        XCTAssertEqual(hapticManager.playedPriorityGroups.filter { $0 == [.tempoCue] }.count, 2)
    }

    func testPauseAndResumeFromResting() {
        let scheduler = TestTimerScheduler()
        let timerManager = TimerManager(scheduler: scheduler)
        let hapticManager = HapticManagerSpy()
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 3, restSeconds: 30),
            timerManager: timerManager,
            hapticManager: hapticManager,
            scheduler: scheduler
        )

        completeCurrentSet(on: viewModel, repsPerSet: 5)

        XCTAssertEqual(viewModel.state, .resting)
        XCTAssertEqual(viewModel.progress.currentSet, 2)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 30)

        scheduler.advance(by: 5)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 25)

        viewModel.pauseWorkout()
        XCTAssertEqual(viewModel.state, .paused)
        XCTAssertEqual(viewModel.pauseContext?.resumeTarget, .resting)

        scheduler.advance(by: 5)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 25)

        viewModel.resumeWorkout()
        XCTAssertEqual(viewModel.state, .resting)
        XCTAssertNil(viewModel.pauseContext)

        scheduler.advance(by: 5)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 20)
    }

    func testCompletingNonFinalSetTransitionsToRestingAndSuppressesRepHaptic() {
        let scheduler = TestTimerScheduler()
        let timerManager = TimerManager(scheduler: scheduler)
        let hapticManager = HapticManagerSpy()
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 3, restSeconds: 45),
            timerManager: timerManager,
            hapticManager: hapticManager,
            scheduler: scheduler
        )

        completeCurrentSet(on: viewModel, repsPerSet: 5)

        XCTAssertEqual(viewModel.state, .resting)
        XCTAssertEqual(viewModel.progress.currentSet, 2)
        XCTAssertEqual(viewModel.progress.currentRep, 0)
        XCTAssertEqual(viewModel.progress.totalCompletedReps, 5)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 45)
        XCTAssertEqual(hapticManager.playedPriorityGroups.last, [.setCompleted, .repCompleted])
    }

    func testCompletingFinalSetTransitionsToCompletedWithWorkoutHapticPriority() {
        let scheduler = TestTimerScheduler()
        let timerManager = TimerManager(scheduler: scheduler)
        let hapticManager = HapticManagerSpy()
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 1, restSeconds: 30),
            timerManager: timerManager,
            hapticManager: hapticManager,
            scheduler: scheduler
        )

        completeCurrentSet(on: viewModel, repsPerSet: 5)

        XCTAssertEqual(viewModel.state, .completed)
        XCTAssertEqual(viewModel.progress.currentSet, 1)
        XCTAssertEqual(viewModel.progress.currentRep, 5)
        XCTAssertEqual(viewModel.progress.totalCompletedReps, 5)
        XCTAssertEqual(hapticManager.playedPriorityGroups.last, [.workoutCompleted, .setCompleted, .repCompleted])
    }

    func testRestCanSkipIntoNextTrainingSetWithoutDuplicateTransitionFeedback() {
        let scheduler = TestTimerScheduler()
        let timerManager = TimerManager(scheduler: scheduler)
        let hapticManager = HapticManagerSpy()
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 2, restSeconds: 30),
            timerManager: timerManager,
            hapticManager: hapticManager,
            scheduler: scheduler
        )

        completeCurrentSet(on: viewModel, repsPerSet: 5)
        XCTAssertEqual(viewModel.state, .resting)

        viewModel.completeRest()
        XCTAssertEqual(viewModel.state, .training)
        XCTAssertEqual(viewModel.progress.currentSet, 2)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 0)
        XCTAssertEqual(hapticManager.playedPriorityGroups.last, [.nextSetStarted])
    }

    func testRestAutomaticallyTransitionsIntoNextTrainingSet() {
        let scheduler = TestTimerScheduler()
        let timerManager = TimerManager(scheduler: scheduler)
        let hapticManager = HapticManagerSpy()
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 2, restSeconds: 15),
            timerManager: timerManager,
            hapticManager: hapticManager,
            scheduler: scheduler
        )

        completeCurrentSet(on: viewModel, repsPerSet: 5)
        XCTAssertEqual(viewModel.state, .resting)

        scheduler.advance(by: 15)

        XCTAssertEqual(viewModel.state, .training)
        XCTAssertEqual(viewModel.progress.currentSet, 2)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 0)
        XCTAssertEqual(hapticManager.playedPriorityGroups.last, [.nextSetStarted])
    }

    func testEndWorkoutConfirmedReturnsToIdleFromSupportedStates() {
        let scheduler = TestTimerScheduler()
        let trainingViewModel = makeTrainingViewModel(
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            scheduler: scheduler
        )
        trainingViewModel.confirmEndWorkout()
        XCTAssertEqual(trainingViewModel.state, .idle)
        XCTAssertEqual(trainingViewModel.progress, .empty)

        let restingScheduler = TestTimerScheduler()
        let restingViewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 2, restSeconds: 30),
            timerManager: TimerManager(scheduler: restingScheduler),
            hapticManager: HapticManagerSpy(),
            scheduler: restingScheduler
        )
        completeCurrentSet(on: restingViewModel, repsPerSet: 5)
        restingViewModel.confirmEndWorkout()
        XCTAssertEqual(restingViewModel.state, .idle)
        XCTAssertEqual(restingViewModel.progress, .empty)

        let pausedScheduler = TestTimerScheduler()
        let pausedViewModel = makeTrainingViewModel(
            timerManager: TimerManager(scheduler: pausedScheduler),
            hapticManager: HapticManagerSpy(),
            scheduler: pausedScheduler
        )
        pausedViewModel.pauseWorkout()
        pausedViewModel.confirmEndWorkout()
        XCTAssertEqual(pausedViewModel.state, .idle)
        XCTAssertEqual(pausedViewModel.progress, .empty)
    }

    func testManualAdjustmentsAreBoundedAndOnlyActiveDuringTraining() {
        let scheduler = TestTimerScheduler()
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 2, restSeconds: 30),
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            scheduler: scheduler
        )

        viewModel.decrementRep()
        XCTAssertEqual(viewModel.progress.currentRep, 0)
        XCTAssertEqual(viewModel.progress.totalCompletedReps, 0)

        completeCurrentSet(on: viewModel, repsPerSet: 5)
        XCTAssertEqual(viewModel.state, .resting)
        XCTAssertEqual(viewModel.progress.totalCompletedReps, 5)

        viewModel.incrementRep()
        viewModel.decrementRep()
        XCTAssertEqual(viewModel.progress.currentRep, 0)
        XCTAssertEqual(viewModel.progress.totalCompletedReps, 5)
    }

    func testCountdownStateRejectsPauseAndManualAdjustments() {
        let scheduler = TestTimerScheduler()
        let viewModel = WorkoutSessionViewModel(
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy()
        )

        viewModel.startWorkout()
        viewModel.pauseWorkout()
        viewModel.incrementRep()
        viewModel.decrementRep()

        XCTAssertEqual(viewModel.state, .countdown)
        XCTAssertEqual(viewModel.progress.currentRep, 0)
        XCTAssertNil(viewModel.pauseContext)
    }

    private func makeTrainingViewModel(
        config: WorkoutConfig = WorkoutConfig(),
        timerManager: any TimerManaging,
        hapticManager: any HapticManaging,
        scheduler: TestTimerScheduler
    ) -> WorkoutSessionViewModel {
        let viewModel = WorkoutSessionViewModel(
            config: config,
            timerManager: timerManager,
            hapticManager: hapticManager,
            tempoCueInterval: 2.0
        )
        viewModel.startWorkout()
        scheduler.advance(by: TimeInterval(config.countdownSeconds))
        return viewModel
    }

    private func completeCurrentSet(on viewModel: WorkoutSessionViewModel, repsPerSet: Int) {
        for _ in 0..<repsPerSet {
            viewModel.incrementRep()
        }
    }
}

final class TimerManagerTests: XCTestCase {
    func testTimerManagerKeepsOnlyOneActiveContext() {
        let scheduler = TestTimerScheduler()
        let manager = TimerManager(scheduler: scheduler)
        var events: [TrainingTimerEvent] = []

        manager.start(.countdown(durationSeconds: 3)) { events.append($0) }
        manager.start(.rest(durationSeconds: 2)) { events.append($0) }

        XCTAssertEqual(manager.activeContext, .rest(durationSeconds: 2))

        scheduler.advance(by: 2)

        XCTAssertEqual(events, [.countdownTick(remainingSeconds: 3), .restTick(remainingSeconds: 1), .restCompleted])
    }

    func testRestPauseAndResumePreservesRemainingSeconds() {
        let scheduler = TestTimerScheduler()
        let manager = TimerManager(scheduler: scheduler)
        var events: [TrainingTimerEvent] = []

        manager.start(.rest(durationSeconds: 3)) { events.append($0) }
        scheduler.advance(by: 1)
        manager.pause()
        scheduler.advance(by: 10)
        manager.resume()
        scheduler.advance(by: 2)

        XCTAssertEqual(events, [.restTick(remainingSeconds: 2), .restTick(remainingSeconds: 1), .restCompleted])
    }
}

final class HapticManagerTests: XCTestCase {
    func testHigherPriorityBusinessEventSuppressesTempoCue() {
        let performer = HapticPerformerSpy()
        let manager = HapticManager(performer: performer)

        let selected = manager.playHighestPriority(among: [.tempoCue, .repCompleted])

        XCTAssertEqual(selected, .repCompleted)
        XCTAssertEqual(performer.patterns, [.light])
    }

    func testWorkoutCompletedOverridesSetAndRepFeedback() {
        let performer = HapticPerformerSpy()
        let manager = HapticManager(performer: performer)

        let selected = manager.playHighestPriority(among: [.repCompleted, .setCompleted, .workoutCompleted])

        XCTAssertEqual(selected, .workoutCompleted)
        XCTAssertEqual(performer.patterns, [.strong])
    }
}

private final class TestTimerScheduler: TimerScheduling {
    private struct ScheduledAction {
        let id: UUID
        let deadline: TimeInterval
        let action: () -> Void
    }

    private var currentTime: TimeInterval = 0
    private var scheduledActions: [ScheduledAction] = []

    @discardableResult
    func schedule(after delay: TimeInterval, action: @escaping () -> Void) -> TimerCancellation {
        let token = TestTimerToken { [weak self] id in
            self?.scheduledActions.removeAll { $0.id == id }
        }

        scheduledActions.append(
            ScheduledAction(
                id: token.id,
                deadline: currentTime + delay,
                action: action
            )
        )

        return token
    }

    func advance(by interval: TimeInterval) {
        let targetTime = currentTime + interval

        while let nextAction = scheduledActions.min(by: { $0.deadline < $1.deadline }), nextAction.deadline <= targetTime {
            currentTime = nextAction.deadline
            scheduledActions.removeAll { $0.id == nextAction.id }
            nextAction.action()
        }

        currentTime = targetTime
    }
}

private final class TestTimerToken: TimerCancellation {
    let id = UUID()
    private let onCancel: (UUID) -> Void

    init(onCancel: @escaping (UUID) -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        onCancel(id)
    }
}

private final class HapticManagerSpy: HapticManaging {
    private(set) var playedEvents: [TrainingHapticEvent] = []
    private(set) var playedPriorityGroups: [[TrainingHapticEvent]] = []

    @discardableResult
    func play(_ event: TrainingHapticEvent) -> TrainingHapticEvent? {
        playedEvents.append(event)
        return event
    }

    @discardableResult
    func playHighestPriority(among events: [TrainingHapticEvent]) -> TrainingHapticEvent? {
        playedPriorityGroups.append(events)
        return events.first
    }
}

private final class HapticPerformerSpy: HapticPerforming {
    private(set) var patterns: [TrainingHapticPattern] = []

    func perform(_ pattern: TrainingHapticPattern) {
        patterns.append(pattern)
    }
}
