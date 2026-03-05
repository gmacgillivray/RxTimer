import XCTest
@testable import WorkoutTimer

final class TimerDurationBugTests: XCTestCase {

    // MARK: - Bug Reproduction Tests

    func testZeroRestMultiSetAdvancesCorrectly() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 60,
            numSets: 2,
            restDurationSeconds: 0
        )
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()

        let exp = expectation(description: "Zero rest set advance")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            engine.completeSet()

            // With zero rest, should immediately start set 2
            XCTAssertEqual(engine.currentSetNumber, 2, "Should advance to set 2 with zero rest")
            XCTAssertEqual(engine.state, .running, "Should be running set 2")

            exp.fulfill()
        }

        wait(for: [exp], timeout: 2.0)
        engine.finish()
    }

    func testTotalDurationWithMultipleSets() {
        // Use non-zero rest + skipRest to avoid the zero-rest bug
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 60,
            numSets: 2,
            restDurationSeconds: 1
        )
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()

        let initialExpectation = expectation(description: "Wait for set 1")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let elapsedSet1 = engine.getCurrentElapsed()
            XCTAssertGreaterThanOrEqual(elapsedSet1, 0.9)
            XCTAssertLessThanOrEqual(elapsedSet1, 1.5)

            engine.completeSet()
            XCTAssertEqual(engine.state, .resting)

            engine.skipRest()
            XCTAssertEqual(engine.currentSetNumber, 2, "Should be on Set 2")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                engine.completeSet()

                let totalDuration = engine.getTotalDuration()
                print("DEBUG: Total Duration: \(totalDuration)")

                XCTAssertLessThan(totalDuration, 2.5, "Total duration is incorrectly double-counting the first set duration!")
                XCTAssertGreaterThan(totalDuration, 1.8, "Total duration should include both sets")

                initialExpectation.fulfill()
            }
        }

        wait(for: [initialExpectation], timeout: 5.0)
    }

    func testTotalDurationWithRest() {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 60,
            numSets: 2,
            restDurationSeconds: 1
        )
        let engine = TimerEngine(configuration: config)

        engine.start()
        engine.skipCountdown()

        let exp = expectation(description: "Run Set 1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            engine.completeSet()
            XCTAssertEqual(engine.state, .resting)

            engine.skipRest()
            XCTAssertEqual(engine.currentSetNumber, 2)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                engine.completeSet()

                let totalDuration = engine.getTotalDuration()
                XCTAssertLessThan(totalDuration, 2.8, "Total duration double counted with rest")

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 5.0)
    }
}
