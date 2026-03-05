import XCTest
@testable import WorkoutTimer

final class RoundTrackerTests: XCTestCase {

    // MARK: - completeRound()

    func testCompleteRoundRecordsSplitTime() {
        let tracker = RoundTracker(numSets: 1)
        let split = tracker.completeRound(currentElapsed: 10.0)

        XCTAssertEqual(split.roundNumber, 1)
        XCTAssertEqual(split.splitTime, 10.0, accuracy: 0.001)
        XCTAssertEqual(split.cumulativeTime, 10.0, accuracy: 0.001)
    }

    func testCompleteRoundIncrementsCount() {
        let tracker = RoundTracker(numSets: 1)
        tracker.completeRound(currentElapsed: 10.0)
        XCTAssertEqual(tracker.roundCount, 1)

        tracker.completeRound(currentElapsed: 25.0)
        XCTAssertEqual(tracker.roundCount, 2)
    }

    func testCompleteRoundUpdatesLastRoundSplitTime() {
        let tracker = RoundTracker(numSets: 1)
        tracker.completeRound(currentElapsed: 10.0)
        XCTAssertEqual(tracker.lastRoundSplitTime, 10.0)

        tracker.completeRound(currentElapsed: 25.0)
        XCTAssertEqual(tracker.lastRoundSplitTime, 15.0)
    }

    func testCompleteMultipleRoundsCalculatesSplitsCorrectly() {
        let tracker = RoundTracker(numSets: 1)
        let split1 = tracker.completeRound(currentElapsed: 10.0)
        let split2 = tracker.completeRound(currentElapsed: 25.0)
        let split3 = tracker.completeRound(currentElapsed: 32.0)

        XCTAssertEqual(split1.splitTime, 10.0, accuracy: 0.001)
        XCTAssertEqual(split2.splitTime, 15.0, accuracy: 0.001)
        XCTAssertEqual(split3.splitTime, 7.0, accuracy: 0.001)
    }

    // MARK: - undoLastRound()

    func testUndoLastRoundDecrementsCount() {
        let tracker = RoundTracker(numSets: 1)
        tracker.completeRound(currentElapsed: 10.0)
        tracker.completeRound(currentElapsed: 20.0)

        let success = tracker.undoLastRound()
        XCTAssertTrue(success)
        XCTAssertEqual(tracker.roundCount, 1)
    }

    func testUndoLastRoundReturnsFalseWhenEmpty() {
        let tracker = RoundTracker(numSets: 1)
        let result = tracker.undoLastRound()
        XCTAssertFalse(result)
    }

    func testUndoLastRoundRestoresLastSplitTime() {
        let tracker = RoundTracker(numSets: 1)
        tracker.completeRound(currentElapsed: 10.0)
        tracker.completeRound(currentElapsed: 25.0)

        tracker.undoLastRound()
        XCTAssertEqual(tracker.lastRoundSplitTime, 10.0)
    }

    func testUndoAllRoundsClearsLastSplitTime() {
        let tracker = RoundTracker(numSets: 1)
        tracker.completeRound(currentElapsed: 10.0)

        tracker.undoLastRound()
        XCTAssertNil(tracker.lastRoundSplitTime)
        XCTAssertEqual(tracker.roundCount, 0)
    }

    // MARK: - completeFinalRound()

    func testCompleteFinalRoundRecordsFinalRound() {
        let tracker = RoundTracker(numSets: 1)
        tracker.completeRound(currentElapsed: 10.0)

        tracker.completeFinalRound(currentElapsed: 15.0, currentSet: 1)

        // Should have saved to allRoundSplits
        XCTAssertEqual(tracker.allRoundSplits[0].count, 2)
        XCTAssertEqual(tracker.allRoundSplits[0].last?.splitTime ?? 0, 5.0, accuracy: 0.001)
    }

    func testCompleteFinalRoundIgnoresTinyRemainder() {
        let tracker = RoundTracker(numSets: 1)
        tracker.completeRound(currentElapsed: 10.0)

        // Only 0.05s elapsed since last round - should be ignored
        tracker.completeFinalRound(currentElapsed: 10.05, currentSet: 1)

        XCTAssertEqual(tracker.allRoundSplits[0].count, 1)
    }

    // MARK: - resetForNewSet()

    func testResetForNewSetClearsCurrentRoundData() {
        let tracker = RoundTracker(numSets: 2)
        tracker.completeRound(currentElapsed: 10.0)
        tracker.completeRound(currentElapsed: 20.0)

        tracker.resetForNewSet()

        XCTAssertEqual(tracker.roundCount, 0)
        XCTAssertTrue(tracker.currentSetRounds.isEmpty)
        XCTAssertNil(tracker.lastRoundSplitTime)
    }

    // MARK: - resetAll()

    func testResetAllReinitializesAllRoundSplitsArray() {
        let tracker = RoundTracker(numSets: 2)
        tracker.completeRound(currentElapsed: 10.0)
        tracker.saveCurrentSetRounds(currentSet: 1)

        tracker.resetAll(numSets: 3)

        XCTAssertEqual(tracker.allRoundSplits.count, 3)
        XCTAssertTrue(tracker.allRoundSplits[0].isEmpty)
        XCTAssertEqual(tracker.roundCount, 0)
    }

    // MARK: - getCurrentRoundElapsed()

    func testGetCurrentRoundElapsedReturnsTimeSinceLastRound() {
        let tracker = RoundTracker(numSets: 1)
        tracker.completeRound(currentElapsed: 10.0)

        let elapsed = tracker.getCurrentRoundElapsed(currentElapsed: 17.5)
        XCTAssertEqual(elapsed, 7.5, accuracy: 0.001)
    }

    func testGetCurrentRoundElapsedFromStart() {
        let tracker = RoundTracker(numSets: 1)

        let elapsed = tracker.getCurrentRoundElapsed(currentElapsed: 5.0)
        XCTAssertEqual(elapsed, 5.0, accuracy: 0.001)
    }

    // MARK: - Multi-Set Flow

    func testMultiSetFlow() {
        let tracker = RoundTracker(numSets: 2)

        // Set 1: 3 rounds
        tracker.completeRound(currentElapsed: 10.0)
        tracker.completeRound(currentElapsed: 20.0)
        tracker.completeRound(currentElapsed: 30.0)
        tracker.saveCurrentSetRounds(currentSet: 1)

        // Reset for set 2
        tracker.resetForNewSet()
        XCTAssertEqual(tracker.roundCount, 0)

        // Set 2: 2 rounds
        tracker.completeRound(currentElapsed: 8.0)
        tracker.completeRound(currentElapsed: 18.0)
        tracker.saveCurrentSetRounds(currentSet: 2)

        // Verify all rounds across sets
        XCTAssertEqual(tracker.allRoundSplits[0].count, 3)
        XCTAssertEqual(tracker.allRoundSplits[1].count, 2)
    }
}
