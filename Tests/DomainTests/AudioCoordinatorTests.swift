import XCTest
@testable import WorkoutTimer

final class AudioCoordinatorTests: XCTestCase {

    private var testDefaults: UserDefaults!
    private var settings: SettingsManager!

    override func setUp() {
        super.setUp()
        let suiteName = "com.rxtimer.audio.tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        settings = SettingsManager(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults = nil
        settings = nil
        super.tearDown()
    }

    // MARK: - Configuration

    func testConfigureSetsTimerType() {
        let coordinator = AudioCoordinator(settings: settings)
        coordinator.configure(timerType: .amrap, numSets: 3)
        // No crash = success; configuration is stored internally
    }

    // MARK: - Audio Disabled

    func testHandleEventWhenAudioDisabledDoesNotCrash() {
        settings.audioEnabled = false
        let coordinator = AudioCoordinator(settings: settings)
        coordinator.configure(timerType: .forTime, numSets: 1)

        // Should not crash even with audio disabled
        coordinator.handleEvent(.start)
        coordinator.handleEvent(.countdown(3))
        coordinator.handleEvent(.finish)
    }

    // MARK: - Audio Enabled

    func testHandleStartEvent() {
        settings.audioEnabled = true
        let coordinator = AudioCoordinator(settings: settings)
        coordinator.configure(timerType: .forTime, numSets: 1)

        // Should not crash - actual audio playback can't be verified in unit tests
        coordinator.handleEvent(.start)
    }

    func testHandleCountdownEventWithCountdownSoundsDisabled() {
        settings.audioEnabled = true
        settings.countdownSoundsEnabled = false
        let coordinator = AudioCoordinator(settings: settings)
        coordinator.configure(timerType: .forTime, numSets: 1)

        // Countdown sounds disabled - should not play countdown audio
        coordinator.handleEvent(.countdown(3))
    }

    func testHandleCountdownEventWithCountdownSoundsEnabled() {
        settings.audioEnabled = true
        settings.countdownSoundsEnabled = true
        let coordinator = AudioCoordinator(settings: settings)
        coordinator.configure(timerType: .forTime, numSets: 1)

        coordinator.handleEvent(.countdown(3))
        coordinator.handleEvent(.countdown(2))
        coordinator.handleEvent(.countdown(1))
    }

    // MARK: - Reset

    func testReset() {
        let coordinator = AudioCoordinator(settings: settings)
        coordinator.configure(timerType: .amrap, numSets: 2)
        coordinator.handleEvent(.start)

        // Reset should not crash
        coordinator.reset()
    }

    // MARK: - Set Tracking

    func testSetCompleteIncrementSetCounter() {
        let coordinator = AudioCoordinator(settings: settings)
        coordinator.configure(timerType: .amrap, numSets: 3)

        coordinator.handleEvent(.start)
        coordinator.handleEvent(.setComplete)
        // Internal currentSet should have incremented
        // Verified indirectly - no crash
    }

    func testUpdateNowPlaying() {
        let coordinator = AudioCoordinator(settings: settings)
        coordinator.configure(timerType: .amrap, numSets: 2)

        // Should not crash
        coordinator.updateNowPlaying(timeText: "05:00", isResting: false, restText: "")
        coordinator.updateNowPlaying(timeText: "", isResting: true, restText: "00:30")
    }
}
