import XCTest
@testable import WorkoutTimer

final class TimerEngineExtendedTests: XCTestCase {

    // MARK: - State Transitions

    func testIdleToCountdownTransition() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        XCTAssertEqual(engine.state, .idle)
        engine.start()
        XCTAssertEqual(engine.state, .countdown)
        XCTAssertTrue(delegate.events.contains(.countdownStart))
    }

    func testSkipCountdownTransitionsToRunning() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()
        XCTAssertEqual(engine.state, .countdown)

        engine.skipCountdown()
        XCTAssertEqual(engine.state, .running)
        XCTAssertTrue(delegate.didReceiveStartEvent)
    }

    func testPauseFromRunning() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()
        XCTAssertEqual(engine.state, .running)

        engine.pause()
        XCTAssertEqual(engine.state, .paused)
    }

    func testResumeFromPaused() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()
        engine.pause()
        engine.resume()
        XCTAssertEqual(engine.state, .running)
    }

    func testFinishFromRunning() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()
        engine.skipCountdown()
        engine.finish()

        XCTAssertEqual(engine.state, .finished)
        XCTAssertTrue(delegate.events.contains(.finish))
    }

    // MARK: - Countdown Pause/Resume

    func testPauseDuringCountdown() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)

        engine.start()
        XCTAssertEqual(engine.state, .countdown)

        engine.pause()
        XCTAssertEqual(engine.state, .countdownPaused)
    }

    func testResumeFromCountdownPaused() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.pause()
        XCTAssertEqual(engine.state, .countdownPaused)

        engine.resume()
        XCTAssertEqual(engine.state, .countdown)
    }

    // MARK: - skipRest()

    func testSkipRestTransitionsToRunning() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 60,
            numSets: 2,
            restDurationSeconds: 30
        )
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()

        // Wait briefly and complete set to trigger rest
        let exp = expectation(description: "Rest state")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            engine.completeSet()
            XCTAssertEqual(engine.state, .resting)

            engine.skipRest()
            XCTAssertEqual(engine.state, .running)
            XCTAssertEqual(engine.currentSetNumber, 2)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
        engine.finish()
    }

    // MARK: - completeSet()

    func testCompleteSetSingleSetFinishesWorkout() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 60,
            numSets: 1
        )
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()
        engine.skipCountdown()

        let exp = expectation(description: "Complete set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            engine.completeSet()
            XCTAssertEqual(engine.state, .finished)
            XCTAssertTrue(delegate.events.contains(.finish))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    func testCompleteSetMultiSetStartsRest() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 60,
            numSets: 3,
            restDurationSeconds: 30
        )
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()
        engine.skipCountdown()

        let exp = expectation(description: "Complete set starts rest")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            engine.completeSet()
            XCTAssertEqual(engine.state, .resting)
            XCTAssertTrue(delegate.events.contains(.restStart))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
        engine.finish()
    }

    // MARK: - Reset

    func testResetClearsAllState() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 60,
            numSets: 2
        )
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()

        let exp = expectation(description: "Reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            engine.reset()
            XCTAssertEqual(engine.state, .idle)
            XCTAssertEqual(engine.getCurrentElapsed(), 0)
            XCTAssertEqual(engine.currentSetNumber, 1)
            XCTAssertTrue(engine.setDurations.isEmpty)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    // MARK: - Bug Detection: start() guard allows .countdown state

    func testStartDuringCountdownIsNoOp() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start() // Goes to countdown
        XCTAssertEqual(engine.state, .countdown)

        // Calling start() during countdown should be a no-op
        engine.start()
        XCTAssertEqual(engine.state, .countdown,
            "start() during countdown should be ignored")

        engine.finish()
    }

    // MARK: - Elapsed Time Tracking

    func testGetCurrentElapsedWhileIdle() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)
        XCTAssertEqual(engine.getCurrentElapsed(), 0)
    }

    func testGetCurrentElapsedWhileRunning() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()

        let exp = expectation(description: "Elapsed time")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let elapsed = engine.getCurrentElapsed()
            XCTAssertGreaterThan(elapsed, 0.9)
            XCTAssertLessThan(elapsed, 1.2)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
        engine.finish()
    }

    func testGetCurrentElapsedWhilePaused() {
        let config = TimerConfiguration(timerType: .forTime)
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()

        let exp = expectation(description: "Paused elapsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            engine.pause()
            let elapsed1 = engine.getCurrentElapsed()

            // Wait a bit - elapsed should not change while paused
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let elapsed2 = engine.getCurrentElapsed()
                XCTAssertEqual(elapsed1, elapsed2, accuracy: 0.01, "Elapsed should not change while paused")
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 3.0)
        engine.finish()
    }

    // MARK: - Set Duration Tracking

    func testSetDurationsRecordedCorrectly() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 60,
            numSets: 2,
            restDurationSeconds: 0
        )
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()

        let exp = expectation(description: "Set durations")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            engine.completeSet()

            // After first set completes and starts set 2 (no rest)
            XCTAssertGreaterThan(engine.setDurations.count, 0, "Should have recorded at least one set duration")

            if let firstSet = engine.setDurations.first {
                XCTAssertGreaterThan(firstSet.workingTime, 0.9)
                XCTAssertEqual(firstSet.setNumber, 1)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3.0)
        engine.finish()
    }

    // MARK: - AMRAP Warning Events

    func testAMRAPLastMinuteWarning() {
        // Create a 62-second AMRAP to test the lastMinute warning
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 62
        )
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()
        engine.skipCountdown()

        // Wait past the 60-second mark (remaining < 60)
        let exp = expectation(description: "Last minute warning")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            XCTAssertTrue(delegate.events.contains(.lastMinute),
                "Should emit lastMinute warning when remaining <= 60s")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 4.0)
        engine.finish()
    }

    // MARK: - EMOM Interval Events

    func testEMOMIntervalTickEmitted() {
        let config = TimerConfiguration(
            timerType: .emom,
            numIntervals: 3,
            intervalDurationSeconds: 2
        )
        let engine = TimerEngine(configuration: config)
        let delegate = MockTimerDelegate()
        engine.delegate = delegate

        engine.start()
        engine.skipCountdown()

        let exp = expectation(description: "EMOM interval")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            XCTAssertTrue(delegate.events.contains(.intervalTick),
                "Should emit intervalTick on EMOM interval transition")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 4.0)
        engine.finish()
    }
}
