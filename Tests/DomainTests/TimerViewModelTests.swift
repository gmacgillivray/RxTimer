import XCTest
import Combine
@testable import WorkoutTimer

final class TimerViewModelTests: XCTestCase {

    var viewModel: TimerViewModel!
    var configuration: TimerConfiguration!

    override func setUp() {
        super.setUp()
        // Setup a standard "For Time" configuration
        configuration = TimerConfiguration(
            timerType: .forTime,
            numSets: 1
        )
        viewModel = TimerViewModel(configuration: configuration)
    }

    override func tearDown() {
        viewModel = nil
        configuration = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.timeText, "00:00")
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.currentSet, 1)
        XCTAssertEqual(viewModel.roundCount, 0)
    }

    func testStartTransitionsToCountdown() {
        viewModel.startTapped()
        // Engine now starts with countdown first
        XCTAssertEqual(viewModel.state, .countdown)
    }

    func testQuickStartReloadsLastWorkoutAndStartsFreshCountdown() throws {
        let suite = "RxTimer.QuickStart.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let stateManager = WorkoutStateManager(userDefaults: defaults)
        let configuration = TimerConfiguration(
            timerType: .emom,
            numIntervals: 7,
            intervalDurationSeconds: 45,
            numSets: 2,
            restDurationSeconds: 35
        )

        do {
            let originalLaunch = LastWorkoutStore(userDefaults: defaults, stateManager: stateManager)
            let original = TimerViewModel(
                configuration: configuration,
                stateManager: stateManager,
                onWorkoutStarted: originalLaunch.recordStartedWorkout
            )
            defer { original.resetTapped() }
            original.startTapped()
            original.skipCountdown()
            original.completeRound()
            XCTAssertEqual(original.roundCount, 1)
        }

        let reloadedDefaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let reloadedLaunch = LastWorkoutStore(
            userDefaults: reloadedDefaults,
            stateManager: WorkoutStateManager(userDefaults: reloadedDefaults)
        )
        let quickStart = try XCTUnwrap(reloadedLaunch.startLastWorkout(), "A workout started before relaunch should be available")
        defer { quickStart.resetTapped() }

        XCTAssertEqual(quickStart.configuration, configuration)
        XCTAssertEqual(quickStart.state, .countdown)
        XCTAssertEqual(quickStart.getCurrentElapsed(), 0)
        XCTAssertEqual(quickStart.currentSet, 1)
        XCTAssertEqual(quickStart.roundCount, 0)
        XCTAssertEqual(quickStart.repCount, 0)
    }

    func testQuickStartUsesTheLatestModeAndIgnoresInvalidStorage() throws {
        let suite = "RxTimer.QuickStart.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let stateManager = WorkoutStateManager(userDefaults: defaults)
        let emom = TimerConfiguration(timerType: .emom, numIntervals: 7, intervalDurationSeconds: 45)
        let amrap = TimerConfiguration(timerType: .amrap, durationSeconds: 420)

        let freshLaunch = LastWorkoutStore(userDefaults: defaults, stateManager: stateManager)
        XCTAssertNil(freshLaunch.configuration)
        XCTAssertNil(freshLaunch.startLastWorkout())

        defaults.set(Data("invalid".utf8), forKey: LastWorkoutStore.storageKey)
        let launch = LastWorkoutStore(userDefaults: defaults, stateManager: stateManager)
        XCTAssertNil(launch.configuration)
        XCTAssertNil(launch.startLastWorkout())

        for configuration in [emom, amrap] {
            let timer = TimerViewModel(
                configuration: configuration,
                stateManager: stateManager,
                onWorkoutStarted: launch.recordStartedWorkout
            )
            timer.startTapped()
            XCTAssertEqual(timer.state, .countdown)
            timer.resetTapped()
        }

        let reloaded = LastWorkoutStore(userDefaults: defaults, stateManager: stateManager)
        let timer = try XCTUnwrap(reloaded.startLastWorkout())
        defer { timer.resetTapped() }
        XCTAssertEqual(timer.configuration, amrap)
        XCTAssertEqual(timer.state, .countdown)
    }

    func testRestoredWorkoutResumesFromSavedElapsedTime() {
        let configuration = TimerConfiguration(timerType: .forTime, numSets: 2)
        let savedWorkout = WorkoutState(
            configuration: configuration,
            state: .paused,
            elapsedSeconds: 65,
            currentSet: 2,
            roundCount: 1
        )
        let restoredViewModel = TimerViewModel(
            configuration: configuration,
            restoredState: savedWorkout
        )
        defer { restoredViewModel.resetTapped() }

        XCTAssertEqual(restoredViewModel.state, .paused)
        XCTAssertEqual(restoredViewModel.timeText, "01:05")
        XCTAssertEqual(restoredViewModel.currentSet, 2)
        XCTAssertEqual(restoredViewModel.roundCount, 1)

        restoredViewModel.resumeTapped()

        guard restoredViewModel.state == .running else {
            XCTFail("Expected Resume to enter running state, got \(restoredViewModel.state)")
            return
        }
        XCTAssertEqual(restoredViewModel.currentSet, 2)
        XCTAssertEqual(restoredViewModel.roundCount, 1)
        let clockAdvanced = expectation(description: "Clock advances past the saved time")
        let observation = restoredViewModel.$timeText
            .filter { $0 == "01:06" }
            .prefix(1)
            .sink { _ in clockAdvanced.fulfill() }
        defer { observation.cancel() }
        wait(for: [clockAdvanced], timeout: 3)
    }

    func testRoundCounting() {
        viewModel.startTapped()
        viewModel.skipCountdown() // Skip countdown to get to running

        XCTAssertEqual(viewModel.state, .running)

        // Simulate completing a round
        viewModel.completeRound()

        XCTAssertEqual(viewModel.roundCount, 1)
        XCTAssertNotNil(viewModel.lastRoundSplitTime)
    }

    func testTimerFormatting() {
        viewModel.startTapped()
        viewModel.skipCountdown()

        // Simulate 65 seconds elapsed via delegate method
        viewModel.timerDidTick(elapsed: 65.0, remaining: nil)

        // Expected format: 01:05
        XCTAssertEqual(viewModel.timeText, "01:05")
    }

    func testAMRAPCountdown() {
        // Setup AMRAP configuration (10 min)
        let amrapConfig = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 600,
            numSets: 1
        )
        let amrapVM = TimerViewModel(configuration: amrapConfig)

        // Initial state should show total duration
        XCTAssertEqual(amrapVM.timeText, "10:00")

        amrapVM.startTapped()
        amrapVM.skipCountdown()

        // Simulate 1 min elapsed (9 min remaining)
        amrapVM.timerDidTick(elapsed: 60.0, remaining: 540.0)

        XCTAssertEqual(amrapVM.timeText, "09:00")
        XCTAssertEqual(amrapVM.elapsedTimeText, "01:00")
    }

    func testReset() {
        viewModel.startTapped()
        viewModel.skipCountdown()
        viewModel.completeRound()
        viewModel.pauseTapped()
        viewModel.resetTapped()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.timeText, "00:00")
        XCTAssertEqual(viewModel.roundCount, 0)
    }
}
