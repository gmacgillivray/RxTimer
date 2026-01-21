import XCTest
@testable import WorkoutTimer

final class StateRestorationTests: XCTestCase {

    var stateManager: WorkoutStateManager!

    override func setUp() {
        super.setUp()
        stateManager = WorkoutStateManager.shared
        // Clear any existing state
        stateManager.clearState()
    }

    override func tearDown() {
        stateManager.clearState()
        super.tearDown()
    }

    // MARK: - Basic Save/Load Tests

    func testSaveAndLoadState() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 300)
        let originalState = WorkoutState(
            configuration: config,
            state: .running,
            elapsedSeconds: 45.0,
            currentSet: 1,
            repCount: 10,
            roundCount: 3
        )

        // Save state
        stateManager.saveState(originalState)

        // Load state
        let loadedState = stateManager.loadState()

        XCTAssertNotNil(loadedState)
        XCTAssertEqual(loadedState?.configuration.timerType, .amrap)
        XCTAssertEqual(loadedState?.elapsedSeconds, 45.0)
        XCTAssertEqual(loadedState?.repCount, 10)
        XCTAssertEqual(loadedState?.roundCount, 3)
        XCTAssertEqual(loadedState?.state, .running)
    }

    func testClearState() {
        let config = TimerConfiguration(timerType: .forTime, timeCapSeconds: 600)
        let state = WorkoutState(configuration: config, state: .running)

        stateManager.saveState(state)
        XCTAssertNotNil(stateManager.loadState())

        stateManager.clearState()
        XCTAssertNil(stateManager.loadState())
    }

    func testLoadStateReturnsNilWhenNothingSaved() {
        let loadedState = stateManager.loadState()
        XCTAssertNil(loadedState)
    }

    // MARK: - Expiry Tests

    func testFreshStateShouldLoad() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 300)
        let state = WorkoutState(
            configuration: config,
            state: .paused,
            lastUpdateTimestamp: Date() // Current time
        )

        stateManager.saveState(state)

        let loadedState = stateManager.loadState()
        XCTAssertNotNil(loadedState, "Fresh state should load successfully")
    }

    func testExpiredStateShouldReturnNil() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 300)

        // Create a state that's 2 hours old (expired)
        let twoHoursAgo = Date().addingTimeInterval(-7200)
        let expiredState = WorkoutState(
            configuration: config,
            state: .paused,
            lastUpdateTimestamp: twoHoursAgo
        )

        stateManager.saveState(expiredState)

        let loadedState = stateManager.loadState()
        XCTAssertNil(loadedState, "Expired state (>1 hour) should return nil")
    }

    func testStateJustUnderExpiryThreshold() {
        let config = TimerConfiguration(timerType: .forTime, timeCapSeconds: 600)

        // Create a state that's 59 minutes old (just under 1 hour)
        let fiftyNineMinutesAgo = Date().addingTimeInterval(-3540)
        let recentState = WorkoutState(
            configuration: config,
            state: .paused,
            lastUpdateTimestamp: fiftyNineMinutesAgo
        )

        stateManager.saveState(recentState)

        let loadedState = stateManager.loadState()
        XCTAssertNotNil(loadedState, "State just under expiry threshold should load")
    }

    // MARK: - Multi-Set State Tests

    func testSaveAndLoadMultiSetState() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 300,
            numSets: 3,
            restDurationSeconds: 60
        )
        let state = WorkoutState(
            configuration: config,
            state: .resting,
            elapsedSeconds: 150.0,
            currentSet: 2,
            roundCount: 5
        )

        stateManager.saveState(state)

        let loadedState = stateManager.loadState()
        XCTAssertEqual(loadedState?.currentSet, 2)
        XCTAssertEqual(loadedState?.state, .resting)
        XCTAssertEqual(loadedState?.configuration.numSets, 3)
        XCTAssertEqual(loadedState?.configuration.restDurationSeconds, 60)
    }

    // MARK: - EMOM State Tests

    func testSaveAndLoadEMOMState() {
        let config = TimerConfiguration(
            timerType: .emom,
            numIntervals: 10,
            intervalDurationSeconds: 60
        )
        let state = WorkoutState(
            configuration: config,
            state: .running,
            elapsedSeconds: 185.0,
            currentInterval: 4
        )

        stateManager.saveState(state)

        let loadedState = stateManager.loadState()
        XCTAssertEqual(loadedState?.currentInterval, 4)
        XCTAssertEqual(loadedState?.configuration.timerType, .emom)
        XCTAssertEqual(loadedState?.configuration.numIntervals, 10)
    }

    // MARK: - Error Handling Tests

    func testCorruptedDataReturnsNil() {
        // Manually write corrupted data to UserDefaults
        UserDefaults.standard.set("corrupted data".data(using: .utf8), forKey: "com.workoutTimer.activeWorkoutState")

        let loadedState = stateManager.loadState()
        XCTAssertNil(loadedState, "Corrupted data should return nil and be cleared")

        // Verify corrupted data was cleared
        let secondAttempt = stateManager.loadState()
        XCTAssertNil(secondAttempt)
    }

    // MARK: - Persistence Across Operations Tests

    func testMultipleSavesOverwrite() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 300)

        let state1 = WorkoutState(configuration: config, state: .running, elapsedSeconds: 10.0)
        stateManager.saveState(state1)

        let state2 = WorkoutState(configuration: config, state: .paused, elapsedSeconds: 25.0)
        stateManager.saveState(state2)

        let loadedState = stateManager.loadState()
        XCTAssertEqual(loadedState?.elapsedSeconds, 25.0, "Latest save should overwrite previous")
        XCTAssertEqual(loadedState?.state, .paused)
    }

    // MARK: - All Timer Types Tests

    func testForTimeStateRestoration() {
        let config = TimerConfiguration(timerType: .forTime, timeCapSeconds: 1200)
        let state = WorkoutState(
            configuration: config,
            state: .running,
            elapsedSeconds: 456.7,
            repCount: 42
        )

        stateManager.saveState(state)
        let loadedState = stateManager.loadState()

        XCTAssertEqual(loadedState?.configuration.timerType, .forTime)
        XCTAssertEqual(loadedState?.repCount, 42)
        XCTAssertEqual(loadedState?.elapsedSeconds, 456.7)
    }

    func testAMRAPStateRestoration() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 600)
        let state = WorkoutState(
            configuration: config,
            state: .running,
            elapsedSeconds: 234.5,
            roundCount: 8
        )

        stateManager.saveState(state)
        let loadedState = stateManager.loadState()

        XCTAssertEqual(loadedState?.configuration.timerType, .amrap)
        XCTAssertEqual(loadedState?.roundCount, 8)
        XCTAssertEqual(loadedState?.configuration.durationSeconds, 600)
    }

    // MARK: - Edge Cases

    func testStateWithZeroElapsedTime() {
        let config = TimerConfiguration(timerType: .forTime, timeCapSeconds: 600)
        let state = WorkoutState(
            configuration: config,
            state: .idle,
            elapsedSeconds: 0.0
        )

        stateManager.saveState(state)
        let loadedState = stateManager.loadState()

        XCTAssertEqual(loadedState?.elapsedSeconds, 0.0)
        XCTAssertEqual(loadedState?.state, .idle)
    }

    func testStateWithLargeElapsedTime() {
        let config = TimerConfiguration(timerType: .forTime, timeCapSeconds: 7200)
        let state = WorkoutState(
            configuration: config,
            state: .running,
            elapsedSeconds: 5432.1 // ~90 minutes
        )

        stateManager.saveState(state)
        let loadedState = stateManager.loadState()

        XCTAssertEqual(loadedState?.elapsedSeconds, 5432.1)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentSaveOperations() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 300)
        let expectation = self.expectation(description: "Concurrent saves")
        expectation.expectedFulfillmentCount = 10

        DispatchQueue.concurrentPerform(iterations: 10) { index in
            let state = WorkoutState(
                configuration: config,
                state: .running,
                elapsedSeconds: Double(index) * 10.0
            )
            stateManager.saveState(state)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Should have saved one of the states successfully
        let loadedState = stateManager.loadState()
        XCTAssertNotNil(loadedState)
    }
}
