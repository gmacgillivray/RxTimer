import XCTest
@testable import RxTimer

final class TimingDriftTests: XCTestCase {

    // MARK: - Configuration Tests

    func testTimerConfigurationCreation() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 600)
        XCTAssertEqual(config.timerType, .amrap)
        XCTAssertEqual(config.durationSeconds, 600)
        XCTAssertEqual(config.totalDurationSeconds, 600)
    }

    func testEMOMTotalDuration() {
        let config = TimerConfiguration(
            timerType: .emom,
            numIntervals: 10,
            intervalDurationSeconds: 60
        )
        XCTAssertEqual(config.totalDurationSeconds, 600)
    }

    func testTimerTypeCountDirection() {
        XCTAssertTrue(TimerType.forTime.countsUp)
        XCTAssertFalse(TimerType.amrap.countsUp)
        XCTAssertTrue(TimerType.emom.countsUp)
    }

    func testMultiSetConfiguration() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 300,
            numSets: 3,
            restDurationSeconds: 60
        )
        XCTAssertEqual(config.numSets, 3)
        XCTAssertEqual(config.restDurationSeconds, 60)
    }

    // MARK: - Timer Engine Tests

    func testTimerEngineInitialization() {
        let config = TimerConfiguration(timerType: .forTime, timeCapSeconds: 600)
        let engine = TimerEngine(configuration: config)

        XCTAssertEqual(engine.state, .idle)
        XCTAssertEqual(engine.currentSetNumber, 1)
    }

    func testTimerEngineStartTransition() {
        let config = TimerConfiguration(timerType: .forTime, timeCapSeconds: 600)
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()

        XCTAssertEqual(engine.state, .running)
        XCTAssertTrue(delegate.didReceiveStartEvent)
    }

    func testTimerEnginePauseResume() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 300)
        let engine = TimerEngine(configuration: config)

        engine.start()
        XCTAssertEqual(engine.state, .running)

        // Wait a bit then pause
        let pauseExpectation = expectation(description: "Wait for pause")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            engine.pause()
            pauseExpectation.fulfill()
        }

        wait(for: [pauseExpectation], timeout: 1.0)
        XCTAssertEqual(engine.state, .paused)

        // Resume
        engine.resume()
        XCTAssertEqual(engine.state, .running)
    }

    func testTimerEngineAccumulatesTimeAcrossPauses() {
        let config = TimerConfiguration(timerType: .forTime, timeCapSeconds: 600)
        let engine = TimerEngine(configuration: config)

        // Start timer
        engine.start()

        // Run for 1 second
        let firstRunExpectation = expectation(description: "First run")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            engine.pause()
            let elapsed1 = engine.getCurrentElapsed()
            XCTAssertGreaterThanOrEqual(elapsed1, 0.95) // Allow small tolerance
            XCTAssertLessThanOrEqual(elapsed1, 1.1)
            firstRunExpectation.fulfill()
        }

        wait(for: [firstRunExpectation], timeout: 2.0)

        // Resume and run for another second
        engine.resume()

        let secondRunExpectation = expectation(description: "Second run")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            engine.pause()
            let elapsed2 = engine.getCurrentElapsed()
            XCTAssertGreaterThanOrEqual(elapsed2, 1.95) // ~2 seconds total
            XCTAssertLessThanOrEqual(elapsed2, 2.2)
            secondRunExpectation.fulfill()
        }

        wait(for: [secondRunExpectation], timeout: 2.0)
    }

    func testTimerEngineReset() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 300)
        let engine = TimerEngine(configuration: config)

        engine.start()

        let runExpectation = expectation(description: "Run before reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            engine.reset()
            runExpectation.fulfill()
        }

        wait(for: [runExpectation], timeout: 1.0)

        XCTAssertEqual(engine.state, .idle)
        XCTAssertEqual(engine.getCurrentElapsed(), 0)
    }

    // MARK: - Timing Accuracy Tests

    func testShortTimerAccuracy() {
        // Test 5-second timer has minimal drift
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 5)
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        let startTime = Date()
        engine.start()

        let expectation = expectation(description: "Timer completes")

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
            let actualDuration = Date().timeIntervalSince(startTime)
            let reportedElapsed = engine.getCurrentElapsed()

            // Drift should be minimal for short duration
            let drift = abs(actualDuration - reportedElapsed)
            XCTAssertLessThanOrEqual(drift, 0.1, "Drift of \(drift)s exceeds tolerance for 5s timer")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 6.0)
    }

    func testAMRAPWarningEvents() {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 90)
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()

        // Wait for 30s warning (at 60s remaining)
        let warningExpectation = expectation(description: "30s warning")

        DispatchQueue.main.asyncAfter(deadline: .now() + 31.0) {
            // Should have received 30s_left event
            XCTAssertTrue(delegate.events.contains("30s_left"))
            warningExpectation.fulfill()
        }

        wait(for: [warningExpectation], timeout: 35.0)
        engine.finish()
    }

    // MARK: - Multi-Set Tests

    func testMultiSetRestPeriod() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 2, // Short for testing
            numSets: 2,
            restDurationSeconds: 1
        )
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()

        let restExpectation = expectation(description: "Enter rest state")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Should be in rest state after first set completes
            XCTAssertEqual(engine.state, .resting)
            XCTAssertTrue(delegate.events.contains("rest_start"))
            restExpectation.fulfill()
        }

        wait(for: [restExpectation], timeout: 4.0)
        engine.finish()
    }

    func testSkipRest() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 2,
            numSets: 2,
            restDurationSeconds: 10 // Long rest
        )
        let engine = TimerEngine(configuration: config)

        engine.start()

        let restExpectation = expectation(description: "Enter rest")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            XCTAssertEqual(engine.state, .resting)

            // Skip rest
            engine.skipRest()

            // Should immediately transition to running for set 2
            XCTAssertEqual(engine.state, .running)
            XCTAssertEqual(engine.currentSetNumber, 2)

            restExpectation.fulfill()
        }

        wait(for: [restExpectation], timeout: 4.0)
        engine.finish()
    }

    func testMultiSetProgression() {
        let config = TimerConfiguration(
            timerType: .forTime,
            timeCapSeconds: 2,
            numSets: 3,
            restDurationSeconds: 1
        )
        let engine = TimerEngine(configuration: config)

        XCTAssertEqual(engine.currentSetNumber, 1)

        engine.start()

        let progressionExpectation = expectation(description: "Set progression")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            // Should be in second set after rest
            XCTAssertGreaterThanOrEqual(engine.currentSetNumber, 2)
            progressionExpectation.fulfill()
        }

        wait(for: [progressionExpectation], timeout: 5.0)
        engine.finish()
    }

    // MARK: - EMOM Tests

    func testEMOMIntervalTransitions() {
        let config = TimerConfiguration(
            timerType: .emom,
            numIntervals: 3,
            intervalDurationSeconds: 2
        )
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()

        let intervalExpectation = expectation(description: "Interval transitions")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Should have received interval_tick event
            XCTAssertTrue(delegate.events.contains("interval_tick"))
            intervalExpectation.fulfill()
        }

        wait(for: [intervalExpectation], timeout: 4.0)
        engine.finish()
    }

    // MARK: - State Tests

    func testWorkoutStateEncoding() throws {
        let config = TimerConfiguration(timerType: .amrap, durationSeconds: 300)
        let state = WorkoutState(
            configuration: config,
            state: .running,
            elapsedSeconds: 45.5,
            currentSet: 1,
            repCount: 10,
            roundCount: 3
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(WorkoutState.self, from: data)

        XCTAssertEqual(decoded.configuration.timerType, .amrap)
        XCTAssertEqual(decoded.elapsedSeconds, 45.5)
        XCTAssertEqual(decoded.repCount, 10)
        XCTAssertEqual(decoded.roundCount, 3)
    }
}

// MARK: - Mock Delegate

class MockTimerDelegate: TimerEngineDelegate {
    var didReceiveStartEvent = false
    var events: [String] = []
    var stateChanges: [TimerState] = []

    func timerDidTick(elapsed: TimeInterval, remaining: TimeInterval?) {
        // Track ticks if needed
    }

    func timerDidEmit(event: String) {
        events.append(event)
        if event == "start" {
            didReceiveStartEvent = true
        }
    }

    func timerDidChangeState(_ state: TimerState) {
        stateChanges.append(state)
    }
}
