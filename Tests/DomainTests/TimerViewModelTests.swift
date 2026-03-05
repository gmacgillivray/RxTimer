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
