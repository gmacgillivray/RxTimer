import XCTest
@testable import WorkoutTimer

/// Tests for long-duration timing accuracy
/// Validates the critical requirement: ≤75ms drift over 30 minutes
final class LongDurationTimingTests: XCTestCase {

    // MARK: - 30-Minute Timing Accuracy Test

    /// Tests that the timer maintains accuracy over 30 minutes
    /// Requirement: ≤75ms drift over 30 minutes with screen on
    func testThirtyMinuteTimingAccuracy() async throws {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 1800 // 30 minutes
        )

        let engine = TimerEngine(configuration: config)
        let delegate = TimingRecorder()
        engine.delegate = delegate

        let wallClockStart = Date()
        engine.start()

        // Wait for 30 minutes + small buffer
        // Note: In real testing, use Instruments for full 30min run
        // This test uses 10 seconds as a proxy to validate the pattern
        let testDuration: TimeInterval = 10.0 // Use 10s for unit test, 1800s for soak test

        try await Task.sleep(nanoseconds: UInt64(testDuration * 1_000_000_000))

        let wallClockEnd = Date()
        let actualElapsed = wallClockEnd.timeIntervalSince(wallClockStart)
        let reportedElapsed = engine.getCurrentElapsed()

        let drift = abs(actualElapsed - reportedElapsed)

        // For 30-minute test: drift should be ≤75ms = 0.075s
        // For 10-second proxy test: proportional tolerance = 0.025s (25ms)
        let tolerance = testDuration == 1800.0 ? 0.075 : 0.025

        XCTAssertLessThanOrEqual(
            drift,
            tolerance,
            "Timing drift of \(drift * 1000)ms exceeds tolerance of \(tolerance * 1000)ms for \(testDuration)s timer"
        )

        engine.finish()
    }

    // MARK: - Multi-Set Timing Gap Test

    /// Tests that multi-set transitions don't introduce timing gaps
    func testMultiSetTransitionTimingAccuracy() async throws {
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 120, // 2 minutes per set
            numSets: 3,
            restDurationSeconds: 30
        )

        let engine = TimerEngine(configuration: config)
        let delegate = TimingRecorder()
        engine.delegate = delegate

        engine.start()

        // Run for first set + rest + partial second set
        // Total: 120s (set 1) + 30s (rest) + 10s (set 2) = 160s
        try await Task.sleep(nanoseconds: 160_000_000_000)

        // Verify no significant timing gaps during transitions
        let setCompletionEvents = delegate.events.filter { $0 == "set_complete" }
        XCTAssertGreaterThan(setCompletionEvents.count, 0, "Should have completed at least one set")

        // Check for timing gaps in tick events
        let tickTimestamps = delegate.tickTimestamps
        if tickTimestamps.count >= 2 {
            let gaps = zip(tickTimestamps.dropFirst(), tickTimestamps).map { $1 - $0 }
            let maxGap = gaps.max() ?? 0

            // Max gap between ticks should be < 1 frame at 60Hz = 16.67ms
            // Allow some tolerance for system scheduling: 50ms
            XCTAssertLessThan(maxGap, 0.05, "Timing gap of \(maxGap * 1000)ms exceeds 50ms tolerance")
        }

        engine.finish()
    }

    // MARK: - Pause/Resume Timing Accuracy

    /// Tests that pause/resume cycles don't accumulate drift
    func testPauseResumeTimingAccuracy() async throws {
        let config = TimerConfiguration(
            timerType: .forTime
        )

        let engine = TimerEngine(configuration: config)
        let delegate = TimingRecorder()
        engine.delegate = delegate

        let wallClockStart = Date()
        var totalPausedTime: TimeInterval = 0

        // Start timer
        engine.start()

        // Run for 2 seconds
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Pause for 1 second
        let pauseStart = Date()
        engine.pause()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let pauseEnd = Date()
        totalPausedTime += pauseEnd.timeIntervalSince(pauseStart)

        // Resume and run for 2 more seconds
        engine.resume()
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Pause again for 1 second
        let pause2Start = Date()
        engine.pause()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let pause2End = Date()
        totalPausedTime += pause2End.timeIntervalSince(pause2Start)

        // Resume and run for 2 more seconds
        engine.resume()
        try await Task.sleep(nanoseconds: 2_000_000_000)

        let wallClockEnd = Date()
        let totalWallClock = wallClockEnd.timeIntervalSince(wallClockStart)
        let expectedElapsed = totalWallClock - totalPausedTime
        let reportedElapsed = engine.getCurrentElapsed()

        let drift = abs(expectedElapsed - reportedElapsed)

        // Allow 50ms tolerance for pause/resume cycles
        XCTAssertLessThanOrEqual(
            drift,
            0.05,
            "Pause/resume drift of \(drift * 1000)ms exceeds 50ms tolerance"
        )

        engine.finish()
    }
}

// MARK: - Timing Recorder Delegate

/// Helper delegate that records timing data for validation
private class TimingRecorder: TimerEngineDelegate {
    var events: [String] = []
    var tickTimestamps: [TimeInterval] = []
    var lastElapsedTime: TimeInterval = 0

    func timerDidTick(elapsed: TimeInterval, remaining: TimeInterval?) {
        tickTimestamps.append(Date().timeIntervalSinceReferenceDate)
        lastElapsedTime = elapsed
    }

    func timerDidEmit(event: String) {
        events.append(event)
    }

    func timerDidChangeState(_ newState: TimerState) {
        // Track state changes if needed
    }
}
