import XCTest
import Combine
@testable import WorkoutTimer

final class TimerViewModelExtendedTests: XCTestCase {

    private var testDefaults: UserDefaults!
    private var settings: SettingsManager!

    override func setUp() {
        super.setUp()
        let suiteName = "com.rxtimer.vm.tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        settings = SettingsManager(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults = nil
        settings = nil
        super.tearDown()
    }

    private func makeViewModel(
        timerType: TimerType = .forTime,
        durationSeconds: Int? = nil,
        timeCapSeconds: Int? = nil,
        numIntervals: Int? = nil,
        intervalDurationSeconds: Int? = nil,
        numSets: Int = 1,
        restDurationSeconds: Int? = nil
    ) -> TimerViewModel {
        let config = TimerConfiguration(
            timerType: timerType,
            timeCapSeconds: timeCapSeconds,
            durationSeconds: durationSeconds,
            numIntervals: numIntervals,
            intervalDurationSeconds: intervalDurationSeconds,
            numSets: numSets,
            restDurationSeconds: restDurationSeconds
        )
        return TimerViewModel(
            configuration: config,
            audioCoordinator: AudioCoordinator(settings: settings),
            hapticCoordinator: HapticCoordinator(settings: settings)
        )
    }

    // MARK: - startTapped()

    func testStartTappedTransitionsToCountdown() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.state, .idle)

        vm.startTapped()
        XCTAssertEqual(vm.state, .countdown)
    }

    func testStartTappedWithSkipCountdownToRunning() {
        let vm = makeViewModel()
        vm.startTapped()
        vm.skipCountdown()
        XCTAssertEqual(vm.state, .running)
    }

    // MARK: - pauseTapped() / resumeTapped()

    func testPauseAndResumeStateManagement() {
        let vm = makeViewModel()
        vm.startTapped()
        vm.skipCountdown()

        vm.pauseTapped()
        XCTAssertEqual(vm.state, .paused)

        vm.resumeTapped()
        XCTAssertEqual(vm.state, .running)
    }

    func testPauseDuringCountdown() {
        let vm = makeViewModel()
        vm.startTapped()
        XCTAssertEqual(vm.state, .countdown)

        vm.pauseTapped()
        XCTAssertEqual(vm.state, .countdownPaused)

        vm.resumeTapped()
        XCTAssertEqual(vm.state, .countdown)
    }

    // MARK: - resetTapped()

    func testResetTappedClearsAllState() {
        let vm = makeViewModel()
        vm.startTapped()
        vm.skipCountdown()
        vm.completeRound()
        vm.pauseTapped()
        vm.resetTapped()

        XCTAssertEqual(vm.state, .idle)
        XCTAssertEqual(vm.timeText, "00:00")
        XCTAssertEqual(vm.roundCount, 0)
        XCTAssertEqual(vm.repCount, 0)
        XCTAssertEqual(vm.currentSet, 1)
        XCTAssertEqual(vm.currentInterval, 1)
        XCTAssertNil(vm.lastRoundSplitTime)
    }

    // MARK: - completeRound()

    func testCompleteRoundDelegatesToRoundTracker() {
        let vm = makeViewModel()
        vm.startTapped()
        vm.skipCountdown()

        vm.completeRound()

        XCTAssertEqual(vm.roundCount, 1)
        XCTAssertNotNil(vm.lastRoundSplitTime)
    }

    func testCompleteMultipleRounds() {
        let vm = makeViewModel()
        vm.startTapped()
        vm.skipCountdown()

        vm.completeRound()
        vm.completeRound()
        vm.completeRound()

        XCTAssertEqual(vm.roundCount, 3)
    }

    func testCompleteRoundWhileNotRunningIsNoOp() {
        let vm = makeViewModel()
        // State is idle - should not complete round
        vm.completeRound()
        XCTAssertEqual(vm.roundCount, 0)
    }

    // MARK: - undoLastRound()

    func testUndoLastRoundSyncsCount() {
        let vm = makeViewModel()
        vm.startTapped()
        vm.skipCountdown()

        vm.completeRound()
        vm.completeRound()
        XCTAssertEqual(vm.roundCount, 2)

        vm.undoLastRound()
        XCTAssertEqual(vm.roundCount, 1)
    }

    func testUndoLastRoundWhenEmptyIsNoOp() {
        let vm = makeViewModel()
        vm.startTapped()
        vm.skipCountdown()

        vm.undoLastRound()
        XCTAssertEqual(vm.roundCount, 0)
    }

    // MARK: - timerDidChangeState(.finished)

    func testFinishedStateSavesWorkout() {
        let vm = makeViewModel()
        vm.startTapped()
        vm.skipCountdown()

        let exp = expectation(description: "Wait for finish")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            vm.finishTapped()
            XCTAssertEqual(vm.state, .finished)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    // MARK: - AMRAP Display

    func testAMRAPInitialDisplayShowsDuration() {
        let vm = makeViewModel(timerType: .amrap, durationSeconds: 600)
        XCTAssertEqual(vm.timeText, "10:00")
        XCTAssertEqual(vm.elapsedTimeText, "00:00")
    }

    func testAMRAPTickShowsRemainingTime() {
        let vm = makeViewModel(timerType: .amrap, durationSeconds: 600)
        vm.startTapped()
        vm.skipCountdown()

        // Simulate tick with 540s remaining
        vm.timerDidTick(elapsed: 60.0, remaining: 540.0)

        XCTAssertEqual(vm.timeText, "09:00")
        XCTAssertEqual(vm.elapsedTimeText, "01:00")
    }

    // MARK: - EMOM Display

    func testEMOMInitialDisplayShowsIntervalDuration() {
        let vm = makeViewModel(
            timerType: .emom,
            numIntervals: 10,
            intervalDurationSeconds: 60
        )
        XCTAssertEqual(vm.timeText, "01:00")
    }

    func testEMOMTickShowsIntervalRemaining() {
        let vm = makeViewModel(
            timerType: .emom,
            numIntervals: 10,
            intervalDurationSeconds: 60
        )
        vm.startTapped()
        vm.skipCountdown()

        // 15 seconds into a 60s interval -> 45s remaining
        vm.timerDidTick(elapsed: 15.0, remaining: 585.0)

        XCTAssertEqual(vm.timeText, "00:45")
    }

    // MARK: - For Time Display

    func testForTimeInitialDisplayShowsZero() {
        let vm = makeViewModel(timerType: .forTime)
        XCTAssertEqual(vm.timeText, "00:00")
    }

    func testForTimeTickShowsElapsedTime() {
        let vm = makeViewModel(timerType: .forTime)
        vm.startTapped()
        vm.skipCountdown()

        // Simulate 2:30 elapsed
        vm.timerDidTick(elapsed: 150.0, remaining: nil)

        XCTAssertEqual(vm.timeText, "02:30")
    }

    // MARK: - Multi-Set ViewModel

    func testCompleteSetTappedWhileNotRunningIsNoOp() {
        let vm = makeViewModel(timerType: .amrap, durationSeconds: 60, numSets: 2)
        vm.completeSetTapped()
        XCTAssertEqual(vm.state, .idle)
    }

    // MARK: - Configuration Properties

    func testViewModelExposesConfigurationProperties() {
        let vm = makeViewModel(
            timerType: .amrap,
            durationSeconds: 600,
            numSets: 3,
            restDurationSeconds: 60
        )
        XCTAssertEqual(vm.timerType, .amrap)
        XCTAssertEqual(vm.numSets, 3)
        XCTAssertEqual(vm.timerTypeDisplayName, "AMRAP")
    }
}
