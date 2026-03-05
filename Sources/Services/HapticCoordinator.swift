import Foundation
import UIKit

class HapticCoordinator {
    private let haptics: HapticService
    private let settings: SettingsManager

    init(hapticService: HapticService = .shared, settings: SettingsManager = .shared) {
        self.haptics = hapticService
        self.settings = settings
    }

    func handleEvent(_ event: TimerEvent) {
        guard settings.hapticsEnabled else { return }
        switch event {
        case .countdown(_):
             // Use a lighter haptic for countdown ticks if desired, 
             // but original code might have mapped specific strings.
             // Original: "countdown_3" -> haptics.trigger(event: "countdown_3")
             // We'll map back to string keys if HapticService expects them, 
             // or better: let HapticService handle the event mapping if refactored.
             // For now, assuming HapticService takes string keys:
             haptics.trigger(event: "countdown") 
        case .start:
            haptics.trigger(event: "start")
        case .finish:
            haptics.trigger(event: "finish")
        case .intervalTick:
            haptics.trigger(event: "interval_tick")
        case .counterIncrement:
            haptics.trigger(event: "counter_increment")
        case .lastMinute:
            haptics.trigger(event: "last_minute")
        case .thirtySecondsLeft:
             haptics.trigger(event: "30s_left")
        case .countdownTick(_):
             haptics.trigger(event: "countdown_10s")
        default:
            break
        }
    }
}
