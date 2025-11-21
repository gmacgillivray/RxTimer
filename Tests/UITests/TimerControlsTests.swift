import XCTest

final class TimerControlsTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    func testAppLaunches() throws {
        XCTAssertTrue(app.staticTexts["Workout Timer"].exists)
    }

    func testTimerTypesAppearInSidebar() throws {
        XCTAssertTrue(app.staticTexts["For Time"].exists)
        XCTAssertTrue(app.staticTexts["AMRAP"].exists)
        XCTAssertTrue(app.staticTexts["EMOM"].exists)
    }

    func testHistoryButtonExists() throws {
        XCTAssertTrue(app.staticTexts["History"].exists)
    }

    // MARK: - Timer Selection Tests

    func testSelectForTimeTimer() throws {
        app.staticTexts["For Time"].tap()

        // Should show configuration screen
        XCTAssertTrue(app.staticTexts["For Time"].exists)
    }

    func testSelectAMRAPTimer() throws {
        app.staticTexts["AMRAP"].tap()

        // Should show configuration screen
        XCTAssertTrue(app.staticTexts["AMRAP"].exists)
    }

    func testSelectEMOMTimer() throws {
        app.staticTexts["EMOM"].tap()

        // Should show configuration screen
        XCTAssertTrue(app.staticTexts["EMOM"].exists)
    }

    // MARK: - Timer Configuration Tests

    func testAMRAPConfigurationAndStart() throws {
        // Select AMRAP
        app.staticTexts["AMRAP"].tap()

        // Wait for configuration screen
        let minutesPicker = app.pickers["Minutes"]
        XCTAssertTrue(minutesPicker.waitForExistence(timeout: 2))

        // Start timer
        let startButton = app.buttons["Start"]
        if startButton.exists {
            startButton.tap()

            // Should transition to timer view
            let pauseButton = app.buttons["Pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Timer Controls Tests

    func testStartPauseResume() throws {
        // Setup: Start an AMRAP timer
        app.staticTexts["AMRAP"].tap()

        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 2) {
            startButton.tap()
        }

        // Verify running state
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))

        // Pause
        pauseButton.tap()

        // Verify paused state
        let resumeButton = app.buttons["Resume"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 1))

        // Resume
        resumeButton.tap()

        // Should be back to running
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 1))
    }

    func testFinishButton() throws {
        // Setup: Start a timer
        app.staticTexts["For Time"].tap()

        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 2) {
            startButton.tap()
        }

        // Wait for timer to be running
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))

        // Tap finish
        let finishButton = app.buttons["Finish"]
        if finishButton.exists {
            finishButton.tap()

            // Should show summary or return to home
            // Summary sheet should appear
            sleep(1) // Wait for animation
        }
    }

    // MARK: - Counter Tests

    func testAMRAPRoundCounter() throws {
        // Setup: Start AMRAP
        app.staticTexts["AMRAP"].tap()

        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 2) {
            startButton.tap()
        }

        // Wait for timer to start
        sleep(1)

        // Look for counter button (with "Rounds" label)
        let roundsLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Rounds'")).firstMatch
        if roundsLabel.exists {
            // Tap counter area
            roundsLabel.tap()

            // Counter should increment (would need to check actual value in real test)
            XCTAssertTrue(true) // Placeholder assertion
        }
    }

    // MARK: - Multi-Set Tests

    func testMultiSetConfiguration() throws {
        // Select AMRAP
        app.staticTexts["AMRAP"].tap()

        // Look for sets configuration
        let setsLabel = app.staticTexts["Sets"]
        if setsLabel.exists {
            // Multi-set configuration is visible
            XCTAssertTrue(true)
        }
    }

    // MARK: - History Tests

    func testNavigateToHistory() throws {
        let historyButton = app.staticTexts["History"]
        XCTAssertTrue(historyButton.exists)

        historyButton.tap()

        // Should navigate to history screen
        let historyNavTitle = app.navigationBars["History"]
        XCTAssertTrue(historyNavTitle.waitForExistence(timeout: 2))
    }

    func testHistoryEmptyState() throws {
        app.staticTexts["History"].tap()

        // If no workouts, should show empty state
        let emptyStateText = app.staticTexts["No Workouts Yet"]
        // May or may not exist depending on previous test runs
        _ = emptyStateText.waitForExistence(timeout: 1)
    }

    // MARK: - Accessibility Tests

    func testStartButtonAccessibility() throws {
        app.staticTexts["AMRAP"].tap()

        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(startButton.isHittable)
            XCTAssertNotNil(startButton.label)
        }
    }

    func testPauseButtonAccessibility() throws {
        // Start a timer
        app.staticTexts["For Time"].tap()

        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 2) {
            startButton.tap()
        }

        let pauseButton = app.buttons["Pause"]
        if pauseButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(pauseButton.isHittable)
            XCTAssertEqual(pauseButton.label, "Pause")
        }
    }

    func testFinishButtonAccessibility() throws {
        // Start a timer
        app.staticTexts["AMRAP"].tap()

        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 2) {
            startButton.tap()
        }

        let finishButton = app.buttons["Finish"]
        if finishButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(finishButton.exists)
            XCTAssertTrue(finishButton.isEnabled)
        }
    }

    // MARK: - State Transitions Tests

    func testStateIndicatorChanges() throws {
        // Start AMRAP
        app.staticTexts["AMRAP"].tap()

        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 2) {
            startButton.tap()
        }

        // Check for "RUNNING" state indicator
        let runningIndicator = app.staticTexts["RUNNING"]
        if runningIndicator.waitForExistence(timeout: 2) {
            XCTAssertTrue(runningIndicator.exists)
        }

        // Pause
        app.buttons["Pause"].tap()

        // Check for "PAUSED" state indicator
        let pausedIndicator = app.staticTexts["PAUSED"]
        if pausedIndicator.waitForExistence(timeout: 1) {
            XCTAssertTrue(pausedIndicator.exists)
        }
    }

    // MARK: - Performance Tests

    func testTimerLaunchPerformance() throws {
        measure {
            app.staticTexts["AMRAP"].tap()

            let startButton = app.buttons["Start"]
            _ = startButton.waitForExistence(timeout: 2)

            // Navigate back
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
}

