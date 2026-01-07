import XCTest
import Combine
@testable import RxTimerApp

final class TimerViewModelTests: XCTestCase {
    
    var viewModel: TimerViewModel!
    var configuration: TimerConfiguration!
    
    override func setUp() {
        super.setUp()
        // Setup a standard "For Time" configuration
        configuration = TimerConfiguration(
            timerType: .forTime,
            name: "Test Workout",
            duration: nil,
            numSets: 1,
            restDuration: nil,
            totalDuration: nil
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
    
    func testStartAndPause() {
        viewModel.startTapped()
        // TimerEngine starts via CADisplayLink, so state should update immediately
        // Note: We access engine state via VM state since VM observes it
        XCTAssertEqual(viewModel.state, .running) // VM updates state synchronously via delegate
        
        viewModel.pauseTapped()
        XCTAssertEqual(viewModel.state, .paused)
        
        viewModel.resumeTapped()
        XCTAssertEqual(viewModel.state, .running)
    }
    
    func testRoundCounting() {
        viewModel.startTapped()
        
        // Simulate completing a round
        viewModel.completeRound()
        
        XCTAssertEqual(viewModel.roundCount, 1)
        XCTAssertEqual(viewModel.currentRoundTimeText, "00:00") // Should reset after round
        
        // Check if round data is stored
        XCTAssertFalse(viewModel.allRounds.isEmpty)
        XCTAssertEqual(viewModel.allRounds[0].count, 1)
        XCTAssertEqual(viewModel.allRounds[0].first?.roundNumber, 1)
    }
    
    func testTimerFormatting() {
        // Manually trigger a tick to verify formatting logic
        // We can't easily wait for real time in unit tests without async expectations
        // But we can call the delegate method directly to simulate
        
        // Simulate 65 seconds elapsed
        viewModel.timerDidTick(elapsed: 65.0, remaining: nil)
        
        // Expected format: 01:05
        XCTAssertEqual(viewModel.timeText, "01:05")
    }
    
    func testAMRAPCountdown() {
        // Setup AMRAP configuration (10 min)
        let amrapConfig = TimerConfiguration(
            timerType: .amrap,
            name: "AMRAP Test",
            duration: nil,
            numSets: 1,
            restDuration: nil,
            totalDuration: 600 // 10 mins
        )
        let amrapVM = TimerViewModel(configuration: amrapConfig)
        
        // Initial state should show total duration
        XCTAssertEqual(amrapVM.timeText, "10:00")
        
        amrapVM.startTapped()
        
        // Simulate 1 min elapsed (9 min remaining)
        amrapVM.timerDidTick(elapsed: 60.0, remaining: 540.0)
        
        XCTAssertEqual(amrapVM.timeText, "09:00")
        XCTAssertEqual(amrapVM.elapsedTimeText, "01:00")
    }
    
    func testReset() {
        viewModel.startTapped()
        viewModel.completeRound()
        viewModel.pauseTapped()
        viewModel.resetTapped()
        
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.timeText, "00:00")
        XCTAssertEqual(viewModel.roundCount, 0)
        XCTAssertTrue(viewModel.allRounds[0].isEmpty)
    }
}
