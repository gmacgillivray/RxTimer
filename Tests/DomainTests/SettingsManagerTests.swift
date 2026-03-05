import XCTest
@testable import WorkoutTimer

final class SettingsManagerTests: XCTestCase {

    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        let suiteName = "com.rxtimer.tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: testDefaults.description)
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Default Values

    func testDefaultAudioEnabled() {
        let settings = SettingsManager(defaults: testDefaults)
        XCTAssertTrue(settings.audioEnabled)
    }

    func testDefaultHapticsEnabled() {
        let settings = SettingsManager(defaults: testDefaults)
        XCTAssertTrue(settings.hapticsEnabled)
    }

    func testDefaultCountdownSoundsEnabled() {
        let settings = SettingsManager(defaults: testDefaults)
        XCTAssertTrue(settings.countdownSoundsEnabled)
    }

    // MARK: - Persistence

    func testAudioSettingPersists() {
        let settings1 = SettingsManager(defaults: testDefaults)
        settings1.audioEnabled = false

        // Create a new instance with the same defaults
        let settings2 = SettingsManager(defaults: testDefaults)
        XCTAssertFalse(settings2.audioEnabled)
    }

    func testHapticsSettingPersists() {
        let settings1 = SettingsManager(defaults: testDefaults)
        settings1.hapticsEnabled = false

        let settings2 = SettingsManager(defaults: testDefaults)
        XCTAssertFalse(settings2.hapticsEnabled)
    }

    func testCountdownSoundsSettingPersists() {
        let settings1 = SettingsManager(defaults: testDefaults)
        settings1.countdownSoundsEnabled = false

        let settings2 = SettingsManager(defaults: testDefaults)
        XCTAssertFalse(settings2.countdownSoundsEnabled)
    }

    // MARK: - Toggle Settings

    func testToggleAudioSetting() {
        let settings = SettingsManager(defaults: testDefaults)
        XCTAssertTrue(settings.audioEnabled)

        settings.audioEnabled = false
        XCTAssertFalse(settings.audioEnabled)

        settings.audioEnabled = true
        XCTAssertTrue(settings.audioEnabled)
    }

    func testToggleHapticsSetting() {
        let settings = SettingsManager(defaults: testDefaults)
        XCTAssertTrue(settings.hapticsEnabled)

        settings.hapticsEnabled = false
        XCTAssertFalse(settings.hapticsEnabled)
    }
}
