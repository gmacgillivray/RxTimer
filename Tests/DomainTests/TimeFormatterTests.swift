import XCTest
@testable import WorkoutTimer

final class TimeFormatterTests: XCTestCase {

    // MARK: - format()

    func testFormatZero() {
        XCTAssertEqual(TimeFormatter.format(0), "00:00")
    }

    func testFormatSubMinute() {
        XCTAssertEqual(TimeFormatter.format(45), "00:45")
    }

    func testFormatExactMinute() {
        XCTAssertEqual(TimeFormatter.format(60), "01:00")
    }

    func testFormatMinutesAndSeconds() {
        XCTAssertEqual(TimeFormatter.format(125), "02:05")
    }

    func testFormatHours() {
        XCTAssertEqual(TimeFormatter.format(3661), "1:01:01")
    }

    func testFormatLargeValue() {
        // 2 hours, 30 minutes, 15 seconds = 9015
        XCTAssertEqual(TimeFormatter.format(9015), "2:30:15")
    }

    func testFormatNegativeClampedToZero() {
        XCTAssertEqual(TimeFormatter.format(-5), "00:00")
    }

    func testFormatFractionalSecondsTruncated() {
        // 65.9 should display as 01:05 (Int truncation)
        XCTAssertEqual(TimeFormatter.format(65.9), "01:05")
    }

    // MARK: - formatForVoiceOver()

    func testVoiceOverZero() {
        XCTAssertEqual(TimeFormatter.formatForVoiceOver(0), "0 seconds")
    }

    func testVoiceOverSingularMinute() {
        XCTAssertEqual(TimeFormatter.formatForVoiceOver(60), "1 minute")
    }

    func testVoiceOverPluralMinutes() {
        XCTAssertEqual(TimeFormatter.formatForVoiceOver(120), "2 minutes")
    }

    func testVoiceOverMinutesAndSeconds() {
        XCTAssertEqual(TimeFormatter.formatForVoiceOver(125), "2 minutes 5 seconds")
    }

    func testVoiceOverHours() {
        XCTAssertEqual(TimeFormatter.formatForVoiceOver(3661), "1 hour 1 minute 1 second")
    }

    func testVoiceOverSingularSecond() {
        XCTAssertEqual(TimeFormatter.formatForVoiceOver(1), "1 second")
    }

    // MARK: - formatDelta()

    func testFormatDeltaPositive() {
        XCTAssertEqual(TimeFormatter.formatDelta(5), "+0:05 slower")
    }

    func testFormatDeltaNegative() {
        XCTAssertEqual(TimeFormatter.formatDelta(-5), "-0:05 faster")
    }

    func testFormatDeltaZero() {
        let result = TimeFormatter.formatDelta(0)
        XCTAssertEqual(result, "0:00 even", "Zero delta should show 'even', not faster/slower")
        XCTAssertFalse(result.contains("-"), "Zero delta should not show negative sign")
        XCTAssertFalse(result.contains("+"), "Zero delta should not show positive sign")
    }

    func testFormatDeltaLargePositive() {
        XCTAssertEqual(TimeFormatter.formatDelta(90), "+1:30 slower")
    }

    // MARK: - formatDeltaForVoiceOver()

    func testFormatDeltaVoiceOverPositive() {
        XCTAssertEqual(TimeFormatter.formatDeltaForVoiceOver(5), "5 seconds slower")
    }

    func testFormatDeltaVoiceOverNegative() {
        XCTAssertEqual(TimeFormatter.formatDeltaForVoiceOver(-5), "5 seconds faster")
    }

    func testFormatDeltaVoiceOverZero() {
        let result = TimeFormatter.formatDeltaForVoiceOver(0)
        XCTAssertEqual(result, "0 seconds even", "Zero delta VoiceOver should show 'even'")
    }

    func testFormatDeltaVoiceOverMinutes() {
        XCTAssertEqual(TimeFormatter.formatDeltaForVoiceOver(90), "1 minute 30 seconds slower")
    }
}
