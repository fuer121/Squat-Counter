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
    func testStartCancelAndCountdownCompletion() {
        let viewModel = WorkoutSessionViewModel()

        viewModel.startWorkout()
        XCTAssertEqual(viewModel.state, .countdown)

        viewModel.cancelCountdown()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.progress, .empty)

        viewModel.startWorkout()
        viewModel.completeCountdown()

        XCTAssertEqual(viewModel.state, .training)
        XCTAssertEqual(viewModel.progress.currentSet, 1)
        XCTAssertEqual(viewModel.progress.currentRep, 0)
    }

    func testPauseAndResumeFromTraining() {
        let viewModel = makeTrainingViewModel()

        viewModel.pauseWorkout()
        XCTAssertEqual(viewModel.state, .paused)
        XCTAssertEqual(viewModel.pauseContext?.resumeTarget, .training)

        viewModel.resumeWorkout()
        XCTAssertEqual(viewModel.state, .training)
        XCTAssertNil(viewModel.pauseContext)
    }

    func testPauseAndResumeFromResting() {
        let viewModel = makeTrainingViewModel(config: WorkoutConfig(repsPerSet: 5, totalSets: 3, restSeconds: 30))

        completeCurrentSet(on: viewModel, repsPerSet: 5)

        XCTAssertEqual(viewModel.state, .resting)
        XCTAssertEqual(viewModel.progress.currentSet, 2)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 30)

        viewModel.pauseWorkout()
        XCTAssertEqual(viewModel.state, .paused)
        XCTAssertEqual(viewModel.pauseContext?.resumeTarget, .resting)

        viewModel.resumeWorkout()
        XCTAssertEqual(viewModel.state, .resting)
        XCTAssertNil(viewModel.pauseContext)
    }

    func testCompletingNonFinalSetTransitionsToResting() {
        let viewModel = makeTrainingViewModel(config: WorkoutConfig(repsPerSet: 5, totalSets: 3, restSeconds: 45))

        completeCurrentSet(on: viewModel, repsPerSet: 5)

        XCTAssertEqual(viewModel.state, .resting)
        XCTAssertEqual(viewModel.progress.currentSet, 2)
        XCTAssertEqual(viewModel.progress.currentRep, 0)
        XCTAssertEqual(viewModel.progress.totalCompletedReps, 5)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 45)
    }

    func testCompletingFinalSetTransitionsToCompleted() {
        let viewModel = makeTrainingViewModel(config: WorkoutConfig(repsPerSet: 5, totalSets: 1, restSeconds: 30))

        completeCurrentSet(on: viewModel, repsPerSet: 5)

        XCTAssertEqual(viewModel.state, .completed)
        XCTAssertEqual(viewModel.progress.currentSet, 1)
        XCTAssertEqual(viewModel.progress.currentRep, 5)
        XCTAssertEqual(viewModel.progress.totalCompletedReps, 5)
    }

    func testRestCanContinueIntoNextTrainingSet() {
        let viewModel = makeTrainingViewModel(config: WorkoutConfig(repsPerSet: 5, totalSets: 2, restSeconds: 30))

        completeCurrentSet(on: viewModel, repsPerSet: 5)
        XCTAssertEqual(viewModel.state, .resting)

        viewModel.completeRest()
        XCTAssertEqual(viewModel.state, .training)
        XCTAssertEqual(viewModel.progress.currentSet, 2)
        XCTAssertEqual(viewModel.progress.remainingRestSeconds, 0)
    }

    func testEndWorkoutConfirmedReturnsToIdleFromSupportedStates() {
        let trainingViewModel = makeTrainingViewModel()
        trainingViewModel.confirmEndWorkout()
        XCTAssertEqual(trainingViewModel.state, .idle)
        XCTAssertEqual(trainingViewModel.progress, .empty)

        let restingViewModel = makeTrainingViewModel(config: WorkoutConfig(repsPerSet: 5, totalSets: 2, restSeconds: 30))
        completeCurrentSet(on: restingViewModel, repsPerSet: 5)
        restingViewModel.confirmEndWorkout()
        XCTAssertEqual(restingViewModel.state, .idle)
        XCTAssertEqual(restingViewModel.progress, .empty)

        let pausedViewModel = makeTrainingViewModel()
        pausedViewModel.pauseWorkout()
        pausedViewModel.confirmEndWorkout()
        XCTAssertEqual(pausedViewModel.state, .idle)
        XCTAssertEqual(pausedViewModel.progress, .empty)
    }

    func testManualAdjustmentsAreBoundedAndOnlyActiveDuringTraining() {
        let viewModel = makeTrainingViewModel(config: WorkoutConfig(repsPerSet: 5, totalSets: 2, restSeconds: 30))

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

    private func makeTrainingViewModel(config: WorkoutConfig = WorkoutConfig()) -> WorkoutSessionViewModel {
        let viewModel = WorkoutSessionViewModel(config: config)
        viewModel.startWorkout()
        viewModel.completeCountdown()
        return viewModel
    }

    private func completeCurrentSet(on viewModel: WorkoutSessionViewModel, repsPerSet: Int) {
        for _ in 0..<repsPerSet {
            viewModel.incrementRep()
        }
    }
}
