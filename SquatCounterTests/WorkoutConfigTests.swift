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

final class SyncPayloadTests: XCTestCase {
    func testConfigPayloadRoundTripsThroughJSONEncoding() throws {
        let payload = SyncPayload.config(WorkoutConfig(repsPerSet: 18, totalSets: 4, restSeconds: 45))
        let data = try JSONEncoder().encode(payload)

        let decoded = try JSONDecoder().decode(SyncPayload.self, from: data)

        XCTAssertEqual(decoded.kind, .config)
        XCTAssertEqual(decoded.config?.repsPerSet, 18)
        XCTAssertEqual(decoded.config?.totalSets, 4)
        XCTAssertEqual(decoded.config?.restSeconds, 45)
        XCTAssertNil(decoded.summary)
    }

    func testWorkoutSummaryPayloadRoundTripsThroughJSONEncoding() throws {
        let summary = WorkoutSummary(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            completedAt: Date(timeIntervalSince1970: 1_710_000_000),
            totalSets: 3,
            totalReps: 45,
            durationSeconds: 120
        )
        let payload = SyncPayload.workoutSummary(summary, updatedAt: summary.completedAt)
        let data = try JSONEncoder().encode(payload)

        let decoded = try JSONDecoder().decode(SyncPayload.self, from: data)

        XCTAssertEqual(decoded.kind, .workoutSummary)
        XCTAssertEqual(decoded.summary, summary)
        XCTAssertNil(decoded.config)
    }
}

final class WorkoutConfigStoreTests: XCTestCase {
    func testStoreReturnsDefaultConfigWhenNothingIsSaved() {
        let suiteName = #function
        let defaults = makeUserDefaults(suiteName: suiteName)
        let store = UserDefaultsWorkoutConfigStore(defaults: defaults)

        let config = store.loadConfig()

        XCTAssertEqual(config, WorkoutConfig())
    }

    func testStorePersistsConfigAcrossStoreInstances() {
        let suiteName = #function
        let defaults = makeUserDefaults(suiteName: suiteName)
        let store = UserDefaultsWorkoutConfigStore(defaults: defaults)
        let saved = WorkoutConfig(repsPerSet: 22, totalSets: 5, restSeconds: 75)

        store.saveConfig(saved)

        let reloaded = UserDefaultsWorkoutConfigStore(defaults: defaults).loadConfig()

        XCTAssertEqual(reloaded.repsPerSet, 22)
        XCTAssertEqual(reloaded.totalSets, 5)
        XCTAssertEqual(reloaded.restSeconds, 75)
        XCTAssertEqual(reloaded.countdownSeconds, WorkoutConfig.countdownSeconds)
        XCTAssertTrue(reloaded.tempoCueEnabled)
    }

    func testStorePersistsClampedConfigValues() {
        let suiteName = #function
        let defaults = makeUserDefaults(suiteName: suiteName)
        let store = UserDefaultsWorkoutConfigStore(defaults: defaults)
        let saved = WorkoutConfig(repsPerSet: 200, totalSets: 0, restSeconds: 999)

        store.saveConfig(saved)

        let reloaded = store.loadConfig()

        XCTAssertEqual(reloaded.repsPerSet, 50)
        XCTAssertEqual(reloaded.totalSets, 1)
        XCTAssertEqual(reloaded.restSeconds, 120)
    }

    private func makeUserDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

final class SquatCalibrationStoreTests: XCTestCase {
    func testCalibrationStorePersistsAndReloadsProfile() {
        let suiteName = #function
        let defaults = makeUserDefaults(suiteName: suiteName)
        let store = UserDefaultsSquatCalibrationStore(defaults: defaults)
        let profile = SquatCalibrationProfile(
            standingGravityX: 0.1,
            standingGravityY: -0.98,
            standingGravityZ: 0.05,
            fullDepthAngle: 0.82,
            standingAngleTolerance: 0.14,
            wristRaiseRateReference: 6.2
        )

        store.saveCalibrationProfile(profile)

        let reloaded = UserDefaultsSquatCalibrationStore(defaults: defaults).loadCalibrationProfile()

        XCTAssertEqual(reloaded, profile)
    }

    func testCalibrationStoreClearsSavedProfile() {
        let suiteName = #function
        let defaults = makeUserDefaults(suiteName: suiteName)
        let store = UserDefaultsSquatCalibrationStore(defaults: defaults)

        store.saveCalibrationProfile(SquatCalibrationProfile())
        XCTAssertNotNil(store.loadCalibrationProfile())

        store.clearCalibrationProfile()

        XCTAssertNil(store.loadCalibrationProfile())
    }

    private func makeUserDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
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

    func testStartWorkoutTriggersCalibrationWhenProfileIsMissing() {
        let scheduler = TestTimerScheduler()
        let defaults = makeUserDefaults(suiteName: #function)
        let calibrationStore = UserDefaultsSquatCalibrationStore(defaults: defaults)
        let motionSampler = SquatMotionSamplerSpy()
        let viewModel = WorkoutSessionViewModel(
            calibrationStore: calibrationStore,
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            motionSampler: motionSampler
        )

        viewModel.startWorkout()

        XCTAssertTrue(viewModel.isCalibrationInProgress)
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(motionSampler.calibrationStartCount, 1)

        let profile = SquatCalibrationProfile()
        motionSampler.completeCalibration(with: .success(profile))

        XCTAssertFalse(viewModel.isCalibrationInProgress)
        XCTAssertEqual(viewModel.state, .countdown)
        XCTAssertEqual(calibrationStore.loadCalibrationProfile(), profile)
    }

    func testCalibrationShowsGuidanceAndCompletionFeedback() {
        let scheduler = TestTimerScheduler()
        let defaults = makeUserDefaults(suiteName: #function)
        let calibrationStore = UserDefaultsSquatCalibrationStore(defaults: defaults)
        let motionSampler = SquatMotionSamplerSpy()
        let viewModel = WorkoutSessionViewModel(
            calibrationStore: calibrationStore,
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            motionSampler: motionSampler
        )

        viewModel.startWorkout()

        XCTAssertEqual(viewModel.detectionStatusMessage, "校准准备中：请保持站立稳定（约 2 秒）")

        motionSampler.completeCalibration(with: .success(SquatCalibrationProfile()))

        XCTAssertEqual(viewModel.detectionStatusMessage, "校准完成，已保存本地校准结果。")
    }

    func testCalibrationFailureKeepsWorkoutIdle() {
        let scheduler = TestTimerScheduler()
        let defaults = makeUserDefaults(suiteName: #function)
        let calibrationStore = UserDefaultsSquatCalibrationStore(defaults: defaults)
        let motionSampler = SquatMotionSamplerSpy()
        let viewModel = WorkoutSessionViewModel(
            calibrationStore: calibrationStore,
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            motionSampler: motionSampler
        )

        viewModel.startWorkout()
        motionSampler.completeCalibration(with: .failure(.insufficientSquatDepth))

        XCTAssertFalse(viewModel.isCalibrationInProgress)
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(calibrationStore.loadCalibrationProfile())
        XCTAssertEqual(viewModel.detectionStatusMessage, "校准失败：请完成一次更完整的深蹲后重试。")
    }

    func testCalibrationFailureForInsufficientRepsShowsExplicitMessage() {
        let scheduler = TestTimerScheduler()
        let defaults = makeUserDefaults(suiteName: #function)
        let calibrationStore = UserDefaultsSquatCalibrationStore(defaults: defaults)
        let motionSampler = SquatMotionSamplerSpy()
        let viewModel = WorkoutSessionViewModel(
            calibrationStore: calibrationStore,
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            motionSampler: motionSampler
        )

        viewModel.startWorkout()
        motionSampler.completeCalibration(with: .failure(.insufficientReps))

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.detectionStatusMessage, "校准失败：有效深蹲次数不足，请按提示连续完成更多深蹲。")
    }

    func testExistingCalibrationSkipsCalibrationAndStartsLiveSampling() {
        let scheduler = TestTimerScheduler()
        let defaults = makeUserDefaults(suiteName: #function)
        let calibrationStore = UserDefaultsSquatCalibrationStore(defaults: defaults)
        let profile = SquatCalibrationProfile(
            standingGravityX: 0.0,
            standingGravityY: -1.0,
            standingGravityZ: 0.0,
            fullDepthAngle: 0.8
        )
        calibrationStore.saveCalibrationProfile(profile)

        let detectionManager = SquatDetectionManagerSpy()
        let motionSampler = SquatMotionSamplerSpy()
        let viewModel = WorkoutSessionViewModel(
            calibrationStore: calibrationStore,
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            detectionManager: detectionManager,
            motionSampler: motionSampler
        )

        viewModel.startWorkout()
        scheduler.advance(by: 3)

        XCTAssertEqual(viewModel.state, .training)
        XCTAssertEqual(motionSampler.calibrationStartCount, 0)
        XCTAssertEqual(motionSampler.liveStartCount, 1)
        XCTAssertEqual(motionSampler.lastLiveProfile, profile)
        XCTAssertEqual(detectionManager.startModes, [.live])
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

    func testSimulationDetectionEventIncrementsRepDuringTraining() {
        let scheduler = TestTimerScheduler()
        let clock = TestClock()
        let hapticManager = HapticManagerSpy()
        let detectionManager = SquatDetectionManager(now: clock.now)
        let viewModel = makeTrainingViewModel(
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: hapticManager,
            detectionManager: detectionManager,
            detectionMode: .simulation,
            internalDebugEnabled: true,
            scheduler: scheduler
        )

        viewModel.simulateRepDetection()

        XCTAssertEqual(viewModel.progress.currentRep, 1)
        XCTAssertEqual(viewModel.progress.totalCompletedReps, 1)
        XCTAssertEqual(hapticManager.playedEvents.last, .repCompleted)
    }

    func testDetectionLifecycleTracksTrainingStateOnly() {
        let scheduler = TestTimerScheduler()
        let hapticManager = HapticManagerSpy()
        let detectionManager = SquatDetectionManagerSpy()
        let viewModel = WorkoutSessionViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 2, restSeconds: 15),
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: hapticManager,
            detectionManager: detectionManager,
            tempoCueInterval: 2.0
        )

        viewModel.startWorkout()
        XCTAssertEqual(detectionManager.startModes, [])
        XCTAssertEqual(detectionManager.stopCount, 1)

        scheduler.advance(by: 3)
        XCTAssertEqual(detectionManager.startModes, [.live])

        viewModel.pauseWorkout()
        XCTAssertEqual(detectionManager.pauseCount, 1)

        viewModel.resumeWorkout()
        XCTAssertEqual(detectionManager.resumeCount, 1)

        completeCurrentSet(on: viewModel, repsPerSet: 5)
        XCTAssertEqual(viewModel.state, .resting)
        XCTAssertEqual(detectionManager.stopCount, 2)

        viewModel.completeRest()
        XCTAssertEqual(viewModel.state, .training)
        XCTAssertEqual(detectionManager.startModes, [.live, .live])

        viewModel.confirmEndWorkout()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(detectionManager.stopCount, 3)
    }

    func testRepDetectedIsIgnoredWhenViewModelIsPaused() {
        let scheduler = TestTimerScheduler()
        let detectionManager = SquatDetectionManagerSpy()
        let viewModel = makeTrainingViewModel(
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            detectionManager: detectionManager,
            scheduler: scheduler
        )

        viewModel.pauseWorkout()
        detectionManager.emit(.repDetected)

        XCTAssertEqual(viewModel.state, .paused)
        XCTAssertEqual(viewModel.progress.currentRep, 0)
        XCTAssertEqual(viewModel.progress.totalCompletedReps, 0)
    }

    func testReceivingConfigDuringTrainingQueuesItUntilSessionEnds() {
        let suiteName = #function
        let defaults = makeUserDefaults(suiteName: suiteName)
        let store = UserDefaultsWorkoutConfigStore(defaults: defaults)
        let scheduler = TestTimerScheduler()
        let notificationCenter = NotificationCenter()
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 10, totalSets: 2, restSeconds: 30),
            configStore: store,
            notificationCenter: notificationCenter,
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            scheduler: scheduler
        )

        let incomingConfig = WorkoutConfig(repsPerSet: 20, totalSets: 4, restSeconds: 60)
        SyncPayloadNotification.post(
            .config(incomingConfig, updatedAt: Date(timeIntervalSince1970: 100)),
            notificationCenter: notificationCenter
        )
        drainMainRunLoop()

        XCTAssertEqual(viewModel.config.repsPerSet, 10)
        XCTAssertEqual(store.loadConfig().repsPerSet, 20)

        viewModel.confirmEndWorkout()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.config.repsPerSet, 20)
        XCTAssertEqual(viewModel.config.totalSets, 4)
        XCTAssertEqual(viewModel.config.restSeconds, 60)
    }

    func testCompletingWorkoutSendsLatestSummaryPayload() {
        let scheduler = TestTimerScheduler()
        let syncCoordinator = SyncCoordinatorSpy()
        let clock = TestDateClock(start: Date(timeIntervalSince1970: 1_700_000_000))
        let summarySent = expectation(description: "workout summary sent")
        syncCoordinator.onSend = { _ in
            summarySent.fulfill()
        }
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 1, restSeconds: 30),
            syncCoordinator: syncCoordinator,
            now: clock.now,
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            scheduler: scheduler
        )

        clock.advance(by: 42)
        completeCurrentSet(on: viewModel, repsPerSet: 5)
        wait(for: [summarySent], timeout: 1.0)

        XCTAssertEqual(viewModel.state, .completed)
        XCTAssertEqual(syncCoordinator.sentPayloads.count, 1)
        XCTAssertEqual(syncCoordinator.sentPayloads.first?.kind, .workoutSummary)
        XCTAssertEqual(syncCoordinator.sentPayloads.first?.summary?.totalReps, 5)
        XCTAssertEqual(syncCoordinator.sentPayloads.first?.summary?.totalSets, 1)
        XCTAssertEqual(syncCoordinator.sentPayloads.first?.summary?.durationSeconds, 42)
    }

    func testHealthManagerFollowsWorkoutLifecycleAndSavesOnCompletion() {
        let scheduler = TestTimerScheduler()
        let healthManager = WorkoutHealthManagerSpy()
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 1, restSeconds: 30),
            healthManager: healthManager,
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            scheduler: scheduler
        )

        drainMainRunLoop()
        XCTAssertEqual(healthManager.startedWorkoutDates.count, 1)

        viewModel.pauseWorkout()
        viewModel.resumeWorkout()
        drainMainRunLoop()

        completeCurrentSet(on: viewModel, repsPerSet: 5)
        drainMainRunLoop()

        XCTAssertEqual(viewModel.state, .completed)
        XCTAssertEqual(healthManager.pauseCount, 1)
        XCTAssertEqual(healthManager.resumeCount, 1)
        XCTAssertEqual(healthManager.finishedSummaries.count, 1)
        XCTAssertEqual(healthManager.finishedSummaries.first?.totalReps, 5)
        XCTAssertEqual(viewModel.healthStatusMessage, "本次训练已写入 Health app。")
    }

    func testHealthAuthorizationDeniedDoesNotBlockTrainingFlow() {
        let scheduler = TestTimerScheduler()
        let healthManager = WorkoutHealthManagerSpy(startResult: .skipped(.sharingDenied))
        let viewModel = makeTrainingViewModel(
            config: WorkoutConfig(repsPerSet: 5, totalSets: 1, restSeconds: 30),
            healthManager: healthManager,
            timerManager: TimerManager(scheduler: scheduler),
            hapticManager: HapticManagerSpy(),
            scheduler: scheduler
        )

        drainMainRunLoop()

        XCTAssertEqual(viewModel.state, .training)
        XCTAssertEqual(viewModel.healthAuthorizationStatus, .sharingDenied)
        XCTAssertEqual(viewModel.healthStatusMessage, "未授权 Health，训练仍可继续，但不会写入 Health app。")

        completeCurrentSet(on: viewModel, repsPerSet: 5)
        drainMainRunLoop()

        XCTAssertEqual(viewModel.state, .completed)
        XCTAssertTrue(healthManager.finishedSummaries.isEmpty)
    }

    private func makeTrainingViewModel(
        config: WorkoutConfig = WorkoutConfig(),
        configStore: WorkoutConfigStoring = UserDefaultsWorkoutConfigStore(defaults: UserDefaults(suiteName: UUID().uuidString)!),
        calibrationStore: any SquatCalibrationStoring = UserDefaultsSquatCalibrationStore(defaults: UserDefaults(suiteName: UUID().uuidString)!),
        syncCoordinator: any WatchConnectivitySyncing = NoopSyncCoordinator(),
        healthManager: any WorkoutHealthManaging = NoopWorkoutHealthManager(),
        notificationCenter: NotificationCenter = .default,
        now: @escaping () -> Date = Date.init,
        timerManager: any TimerManaging,
        hapticManager: any HapticManaging,
        detectionManager: any SquatDetectionManaging = SquatDetectionManagerSpy(),
        motionSampler: any SquatMotionSampling = NoopSquatMotionSampler(),
        detectionMode: SquatDetectionMode = .live,
        internalDebugEnabled: Bool = false,
        scheduler: TestTimerScheduler
    ) -> WorkoutSessionViewModel {
        let viewModel = WorkoutSessionViewModel(
            config: config,
            configStore: configStore,
            calibrationStore: calibrationStore,
            syncCoordinator: syncCoordinator,
            healthManager: healthManager,
            notificationCenter: notificationCenter,
            now: now,
            timerManager: timerManager,
            hapticManager: hapticManager,
            detectionManager: detectionManager,
            motionSampler: motionSampler,
            detectionMode: detectionMode,
            internalDebugEnabled: internalDebugEnabled,
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

    private func makeUserDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func drainMainRunLoop() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))
    }
}

final class SquatDetectionManagerTests: XCTestCase {
    func testSimulationModeEmitsRepAndRespectsCooldown() {
        let clock = TestClock()
        let manager = SquatDetectionManager(now: clock.now)
        var events: [SquatDetectionEvent] = []

        manager.start(mode: .simulation) { events.append($0) }
        manager.simulateRep()
        manager.simulateRep()

        XCTAssertEqual(events, [
            .motionStateChanged(.descending),
            .motionStateChanged(.bottom),
            .motionStateChanged(.ascending),
            .motionStateChanged(.repCompleted),
            .repDetected,
            .motionStateChanged(.standing)
        ])

        clock.advance(by: 1.0)
        manager.simulateRep()

        XCTAssertEqual(events.filter { $0 == .repDetected }.count, 2)
    }

    func testLiveModeRecognizesAFullRepAfterStableStanding() {
        let thresholds = SquatDetectionThresholds(
            descendingThreshold: 0.3,
            bottomThreshold: 0.7,
            ascendingThreshold: 0.45,
            standingThreshold: 0.12,
            standingStabilityDuration: 0.3,
            cooldownDuration: 0.8,
            maximumWristRaiseMagnitude: 0.45
        )
        let manager = SquatDetectionManager(thresholds: thresholds)
        var events: [SquatDetectionEvent] = []

        manager.start(mode: .live) { events.append($0) }
        manager.process(SquatMotionSample(timestamp: 0.0, normalizedDepth: 0.05))
        manager.process(SquatMotionSample(timestamp: 0.35, normalizedDepth: 0.05))
        manager.process(SquatMotionSample(timestamp: 0.45, normalizedDepth: 0.35))
        manager.process(SquatMotionSample(timestamp: 0.55, normalizedDepth: 0.75))
        manager.process(SquatMotionSample(timestamp: 0.7, normalizedDepth: 0.4))
        manager.process(SquatMotionSample(timestamp: 0.85, normalizedDepth: 0.05))

        XCTAssertEqual(events, [
            .motionStateChanged(.descending),
            .motionStateChanged(.bottom),
            .motionStateChanged(.ascending),
            .motionStateChanged(.repCompleted),
            .repDetected,
            .motionStateChanged(.standing)
        ])
    }

    func testLiveModeRejectsHalfSquatAndWristRaiseFalseTrigger() {
        let thresholds = SquatDetectionThresholds(
            descendingThreshold: 0.3,
            bottomThreshold: 0.7,
            ascendingThreshold: 0.45,
            standingThreshold: 0.12,
            standingStabilityDuration: 0.3,
            cooldownDuration: 0.8,
            maximumWristRaiseMagnitude: 0.25
        )
        let manager = SquatDetectionManager(thresholds: thresholds)
        var events: [SquatDetectionEvent] = []

        manager.start(mode: .live) { events.append($0) }
        manager.process(SquatMotionSample(timestamp: 0.0, normalizedDepth: 0.05))
        manager.process(SquatMotionSample(timestamp: 0.35, normalizedDepth: 0.05))
        manager.process(SquatMotionSample(timestamp: 0.45, normalizedDepth: 0.4))
        manager.process(SquatMotionSample(timestamp: 0.6, normalizedDepth: 0.05))
        manager.process(SquatMotionSample(timestamp: 1.0, normalizedDepth: 0.1, wristRaiseMagnitude: 0.6))
        manager.process(SquatMotionSample(timestamp: 1.2, normalizedDepth: 0.05))

        XCTAssertFalse(events.contains(.repDetected))
        XCTAssertEqual(manager.currentMotionState, .standing)
    }

    func testThresholdsClampIntoSupportedRanges() {
        let thresholds = SquatDetectionThresholds(
            descendingThreshold: 0.0,
            bottomThreshold: 0.1,
            ascendingThreshold: 2.0,
            standingThreshold: -1.0,
            standingStabilityDuration: -1.0,
            cooldownDuration: -1.0,
            maximumWristRaiseMagnitude: 3.0
        )

        XCTAssertEqual(thresholds.standingThreshold, 0.0)
        XCTAssertGreaterThan(thresholds.descendingThreshold, thresholds.standingThreshold)
        XCTAssertGreaterThan(thresholds.bottomThreshold, thresholds.descendingThreshold)
        XCTAssertLessThan(thresholds.ascendingThreshold, thresholds.bottomThreshold)
        XCTAssertEqual(thresholds.standingStabilityDuration, 0.0)
        XCTAssertEqual(thresholds.cooldownDuration, 0.0)
        XCTAssertEqual(thresholds.maximumWristRaiseMagnitude, 1.0)
    }
}

private final class WorkoutHealthManagerSpy: WorkoutHealthManaging {
    private let startResult: WorkoutHealthSessionStartResult
    private let finishResult: WorkoutHealthSaveResult

    private(set) var startedWorkoutDates: [Date] = []
    private(set) var finishedSummaries: [WorkoutSummary] = []
    private(set) var finishDates: [Date] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var discardCount = 0

    init(
        startResult: WorkoutHealthSessionStartResult = .started,
        finishResult: WorkoutHealthSaveResult = .saved
    ) {
        self.startResult = startResult
        self.finishResult = finishResult
    }

    func prepareForWorkout(at startDate: Date) async -> WorkoutHealthSessionStartResult {
        startedWorkoutDates.append(startDate)
        return startResult
    }

    func pauseWorkout() async {
        pauseCount += 1
    }

    func resumeWorkout() async {
        resumeCount += 1
    }

    func finishWorkout(summary: WorkoutSummary, endDate: Date) async -> WorkoutHealthSaveResult {
        guard case .started = startResult else {
            return finishResult
        }

        finishedSummaries.append(summary)
        finishDates.append(endDate)
        return finishResult
    }

    func discardWorkout() async {
        discardCount += 1
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

private final class TestClock {
    private(set) var currentTime: TimeInterval = 0

    func now() -> TimeInterval {
        currentTime
    }

    func advance(by interval: TimeInterval) {
        currentTime += interval
    }
}

private final class SquatDetectionManagerSpy: SquatDetectionManaging {
    private(set) var startModes: [SquatDetectionMode] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var stopCount = 0
    private(set) var simulatedRepCount = 0
    private(set) var processedSamples: [SquatMotionSample] = []
    private var handler: ((SquatDetectionEvent) -> Void)?

    private(set) var mode: SquatDetectionMode?
    private(set) var isActive = false
    private(set) var isPaused = false
    private(set) var currentMotionState: SquatMotionState = .standing
    let thresholds = SquatDetectionThresholds()

    func start(mode: SquatDetectionMode, handler: @escaping (SquatDetectionEvent) -> Void) {
        startModes.append(mode)
        self.mode = mode
        self.handler = handler
        isActive = true
        isPaused = false
        currentMotionState = .standing
    }

    func pause() {
        pauseCount += 1
        isPaused = true
    }

    func resume() {
        resumeCount += 1
        isPaused = false
    }

    func stop() {
        stopCount += 1
        mode = nil
        handler = nil
        isActive = false
        isPaused = false
        currentMotionState = .standing
    }

    func simulateRep() {
        simulatedRepCount += 1
    }

    func process(_ sample: SquatMotionSample) {
        processedSamples.append(sample)
    }

    func emit(_ event: SquatDetectionEvent) {
        handler?(event)
    }
}

private final class SquatMotionSamplerSpy: SquatMotionSampling {
    private(set) var isSamplingActive = false
    private(set) var isPaused = false

    private(set) var calibrationStartCount = 0
    private(set) var liveStartCount = 0
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var stopCount = 0
    private(set) var lastLiveProfile: SquatCalibrationProfile?
    private(set) var progressEvents: [SquatCalibrationPhase] = []

    private var calibrationHandler: ((SquatCalibrationResult) -> Void)?

    func startCalibration(
        progress: @escaping (SquatCalibrationPhase) -> Void,
        completion: @escaping (SquatCalibrationResult) -> Void
    ) {
        calibrationStartCount += 1
        isSamplingActive = true
        isPaused = false
        calibrationHandler = completion
        progressEvents.append(.preparingStanding(secondsRemaining: 2))
        progress(.preparingStanding(secondsRemaining: 2))
    }

    func completeCalibration(with result: SquatCalibrationResult) {
        let handler = calibrationHandler
        calibrationHandler = nil
        isSamplingActive = false
        handler?(result)
    }

    func startLiveSampling(with profile: SquatCalibrationProfile, handler: @escaping (SquatMotionSample) -> Void) {
        liveStartCount += 1
        lastLiveProfile = profile
        isSamplingActive = true
        isPaused = false
    }

    func pause() {
        pauseCount += 1
        isPaused = true
    }

    func resume() {
        resumeCount += 1
        isPaused = false
    }

    func stop() {
        stopCount += 1
        isSamplingActive = false
        isPaused = false
        calibrationHandler = nil
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

private final class SyncCoordinatorSpy: WatchConnectivitySyncing, @unchecked Sendable {
    private(set) var sentPayloads: [SyncPayload] = []
    var onSend: (@Sendable (SyncPayload) -> Void)?

    func send(payload: SyncPayload) async throws {
        sentPayloads.append(payload)
        onSend?(payload)
    }
}

private final class TestDateClock {
    private(set) var currentDate: Date

    init(start: Date) {
        currentDate = start
    }

    func now() -> Date {
        currentDate
    }

    func advance(by interval: TimeInterval) {
        currentDate.addTimeInterval(interval)
    }
}
