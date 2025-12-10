import Foundation
import SwiftUI

/// ViewModel for timer selection screen
/// Manages configuration loading and persistence
final class TimerSelectionViewModel: ObservableObject {
    // MARK: - Callbacks

    private let onSelectTimer: (TimerType) -> Void
    private let onNavigateToHistory: () -> Void

    // MARK: - Configuration Storage

    private let userDefaults = UserDefaults.standard
    private let configKeyPrefix = "LastUsedConfig"

    // MARK: - Initialization

    init(
        onSelectTimer: @escaping (TimerType) -> Void,
        onNavigateToHistory: @escaping () -> Void
    ) {
        self.onSelectTimer = onSelectTimer
        self.onNavigateToHistory = onNavigateToHistory
    }

    // MARK: - Public Methods

    /// Load saved or default configuration for a timer type
    func configuration(for timerType: TimerType) -> TimerConfiguration {
        let key = "\(configKeyPrefix).\(timerType.rawValue)"

        // Try loading saved configuration
        if let data = userDefaults.data(forKey: key),
           let config = try? JSONDecoder().decode(TimerConfiguration.self, from: data) {
            return config
        }

        // Fallback to default configuration
        return TimerConfiguration.defaultConfiguration(for: timerType)
    }

    /// Save configuration for future use
    func saveConfiguration(_ config: TimerConfiguration) {
        let key = "\(configKeyPrefix).\(config.timerType.rawValue)"

        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: key)
            userDefaults.synchronize()
        }
    }

    /// User tapped timer card - navigate to configuration
    func selectTimer(_ timerType: TimerType) {
        onSelectTimer(timerType)
    }

    /// Navigate to workout history
    func navigateToHistory() {
        onNavigateToHistory()
    }

    // MARK: - Recent Workout

    /// Most recent workout for display (stub - would connect to Core Data)
    var mostRecentWorkout: WorkoutSummaryData? {
        // TODO: Fetch from Core Data WorkoutHistoryManager
        // For now, return nil to avoid compilation errors
        return nil
    }
}
