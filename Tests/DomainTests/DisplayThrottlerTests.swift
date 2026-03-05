import XCTest
@testable import WorkoutTimer

final class DisplayThrottlerTests: XCTestCase {

    func testFirstCallAlwaysReturnsTrue() {
        let throttler = DisplayThrottler(updateInterval: 1.0)
        let now = Date()
        XCTAssertTrue(throttler.shouldUpdate(.time, now: now))
    }

    func testCallWithinIntervalReturnsFalse() {
        let throttler = DisplayThrottler(updateInterval: 1.0)
        let now = Date()
        _ = throttler.shouldUpdate(.time, now: now)

        // 0.5s later - should be throttled
        let later = now.addingTimeInterval(0.5)
        XCTAssertFalse(throttler.shouldUpdate(.time, now: later))
    }

    func testCallAfterIntervalReturnsTrue() {
        let throttler = DisplayThrottler(updateInterval: 1.0)
        let now = Date()
        _ = throttler.shouldUpdate(.time, now: now)

        // 1.0s later - should be allowed
        let later = now.addingTimeInterval(1.0)
        XCTAssertTrue(throttler.shouldUpdate(.time, now: later))
    }

    func testIndependentCategoriesDontInterfere() {
        let throttler = DisplayThrottler(updateInterval: 1.0)
        let now = Date()

        // Update .time
        XCTAssertTrue(throttler.shouldUpdate(.time, now: now))

        // .elapsed should still be allowed since it's a different category
        XCTAssertTrue(throttler.shouldUpdate(.elapsed, now: now))

        // .time should be throttled
        XCTAssertFalse(throttler.shouldUpdate(.time, now: now.addingTimeInterval(0.5)))
    }

    func testResetAllClearsAllTimestamps() {
        let throttler = DisplayThrottler(updateInterval: 1.0)
        let now = Date()

        _ = throttler.shouldUpdate(.time, now: now)
        _ = throttler.shouldUpdate(.elapsed, now: now)
        _ = throttler.shouldUpdate(.rest, now: now)

        throttler.resetAll()

        // All categories should be allowed again immediately
        let sameTime = now.addingTimeInterval(0.1)
        XCTAssertTrue(throttler.shouldUpdate(.time, now: sameTime))
        XCTAssertTrue(throttler.shouldUpdate(.elapsed, now: sameTime))
        XCTAssertTrue(throttler.shouldUpdate(.rest, now: sameTime))
    }

    func testCustomUpdateInterval() {
        let throttler = DisplayThrottler(updateInterval: 0.5)
        let now = Date()

        XCTAssertTrue(throttler.shouldUpdate(.time, now: now))
        XCTAssertFalse(throttler.shouldUpdate(.time, now: now.addingTimeInterval(0.3)))
        XCTAssertTrue(throttler.shouldUpdate(.time, now: now.addingTimeInterval(0.5)))
    }

    func testRoundCategory() {
        let throttler = DisplayThrottler(updateInterval: 1.0)
        let now = Date()

        XCTAssertTrue(throttler.shouldUpdate(.round, now: now))
        XCTAssertFalse(throttler.shouldUpdate(.round, now: now.addingTimeInterval(0.9)))
        XCTAssertTrue(throttler.shouldUpdate(.round, now: now.addingTimeInterval(1.0)))
    }
}
