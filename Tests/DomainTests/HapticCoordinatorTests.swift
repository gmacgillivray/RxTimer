import XCTest
@testable import WorkoutTimer

final class HapticCoordinatorTests: XCTestCase {

    private var testDefaults: UserDefaults!
    private var settings: SettingsManager!

    override func setUp() {
        super.setUp()
        let suiteName = "com.rxtimer.haptic.tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        settings = SettingsManager(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults = nil
        settings = nil
        super.tearDown()
    }

    // MARK: - Haptics Disabled

    func testHandleEventWhenHapticsDisabledDoesNotCrash() {
        settings.hapticsEnabled = false
        let coordinator = HapticCoordinator(settings: settings)

        // Should return early without triggering any haptics
        coordinator.handleEvent(.start)
        coordinator.handleEvent(.finish)
        coordinator.handleEvent(.counterIncrement)
        coordinator.handleEvent(.lastMinute)
    }

    // MARK: - Haptics Enabled

    func testHandleStartEvent() {
        settings.hapticsEnabled = true
        let coordinator = HapticCoordinator(settings: settings)
        coordinator.handleEvent(.start)
        // No crash = haptic trigger path works
    }

    func testHandleFinishEvent() {
        settings.hapticsEnabled = true
        let coordinator = HapticCoordinator(settings: settings)
        coordinator.handleEvent(.finish)
    }

    func testHandleCounterIncrementEvent() {
        settings.hapticsEnabled = true
        let coordinator = HapticCoordinator(settings: settings)
        coordinator.handleEvent(.counterIncrement)
    }

    func testHandleLastMinuteEvent() {
        settings.hapticsEnabled = true
        let coordinator = HapticCoordinator(settings: settings)
        coordinator.handleEvent(.lastMinute)
    }

    func testHandleThirtySecondsLeftEvent() {
        settings.hapticsEnabled = true
        let coordinator = HapticCoordinator(settings: settings)
        coordinator.handleEvent(.thirtySecondsLeft)
    }

    func testHandleIntervalTickEvent() {
        settings.hapticsEnabled = true
        let coordinator = HapticCoordinator(settings: settings)
        coordinator.handleEvent(.intervalTick)
    }
}
