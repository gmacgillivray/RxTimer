import Foundation
import SwiftUI

final class LastWorkoutStore: ObservableObject {
    static let storageKey = "LastStartedWorkoutConfiguration"

    @Published private(set) var configuration: TimerConfiguration?
    private let userDefaults: UserDefaults
    private let stateManager: WorkoutStateManager

    init(userDefaults: UserDefaults = .standard, stateManager: WorkoutStateManager = .shared) {
        self.userDefaults = userDefaults
        self.stateManager = stateManager
        if let data = userDefaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(TimerConfiguration.self, from: data),
           Self.isValid(saved) {
            configuration = saved
        }
    }

    func recordStartedWorkout(_ configuration: TimerConfiguration) {
        guard Self.isValid(configuration), let data = try? JSONEncoder().encode(configuration) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
        self.configuration = configuration
    }

    func startLastWorkout() -> TimerViewModel? {
        guard let configuration else { return nil }
        let timer = TimerViewModel(configuration: configuration, stateManager: stateManager)
        timer.startTapped()
        return timer
    }

    private static func isValid(_ configuration: TimerConfiguration) -> Bool {
        guard configuration.numSets > 0, (configuration.restDurationSeconds ?? 0) >= 0 else { return false }
        switch configuration.timerType {
        case .forTime:
            return (configuration.timeCapSeconds ?? 1) > 0
        case .amrap:
            return (configuration.durationSeconds ?? 0) > 0
        case .emom:
            guard let count = configuration.numIntervals, count > 0,
                  let duration = configuration.intervalDurationSeconds, duration > 0 else { return false }
            return !count.multipliedReportingOverflow(by: duration).overflow
        }
    }
}

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
