import Foundation
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults: UserDefaults

    private enum Keys {
        static let audioEnabled = "com.rxtimer.settings.audioEnabled"
        static let hapticsEnabled = "com.rxtimer.settings.hapticsEnabled"
        static let countdownSoundsEnabled = "com.rxtimer.settings.countdownSoundsEnabled"
    }

    @Published var audioEnabled: Bool {
        didSet { defaults.set(audioEnabled, forKey: Keys.audioEnabled) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    @Published var countdownSoundsEnabled: Bool {
        didSet { defaults.set(countdownSoundsEnabled, forKey: Keys.countdownSoundsEnabled) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Default to true if not previously set
        if defaults.object(forKey: Keys.audioEnabled) == nil {
            defaults.set(true, forKey: Keys.audioEnabled)
        }
        if defaults.object(forKey: Keys.hapticsEnabled) == nil {
            defaults.set(true, forKey: Keys.hapticsEnabled)
        }
        if defaults.object(forKey: Keys.countdownSoundsEnabled) == nil {
            defaults.set(true, forKey: Keys.countdownSoundsEnabled)
        }

        self.audioEnabled = defaults.bool(forKey: Keys.audioEnabled)
        self.hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        self.countdownSoundsEnabled = defaults.bool(forKey: Keys.countdownSoundsEnabled)
    }
}
