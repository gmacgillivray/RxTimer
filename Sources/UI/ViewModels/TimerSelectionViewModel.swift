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
           saved.isUsable {
            configuration = saved
        }
    }

    func recordStartedWorkout(_ configuration: TimerConfiguration) {
        guard configuration.isUsable, let data = try? JSONEncoder().encode(configuration) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
        self.configuration = configuration
    }

    func startLastWorkout() -> TimerViewModel? {
        guard let configuration else { return nil }
        return startWorkout(configuration)
    }

    func startWorkout(_ configuration: TimerConfiguration) -> TimerViewModel {
        let timer = TimerViewModel(
            configuration: configuration,
            stateManager: stateManager,
            onWorkoutStarted: recordStartedWorkout
        )
        timer.startTapped()
        return timer
    }

}

extension TimerConfiguration {
    var isUsable: Bool {
        let maximumTime = 99 * 60 + 59
        guard (1...10).contains(numSets), (0...maximumTime).contains(restDurationSeconds ?? 0) else { return false }
        switch timerType {
        case .forTime:
            return (1...maximumTime).contains(timeCapSeconds ?? 1)
        case .amrap:
            return (1...maximumTime).contains(durationSeconds ?? 0)
        case .emom:
            return (1...60).contains(numIntervals ?? 0)
                && (1...maximumTime).contains(intervalDurationSeconds ?? 0)
        }
    }

    func workoutDetails(spoken: Bool = false) -> String {
        func time(_ seconds: Int) -> String {
            if spoken { return TimeFormatter.formatForVoiceOver(Double(seconds)) }
            let formatted = TimeFormatter.format(Double(seconds))
            return formatted.hasPrefix("0") ? String(formatted.dropFirst()) : formatted
        }

        var details: [String] = []
        switch timerType {
        case .forTime:
            details.append(timeCapSeconds.map { "\(time($0)) cap" } ?? "No time cap")
        case .amrap:
            if let durationSeconds { details.append(time(durationSeconds)) }
        case .emom:
            if let numIntervals, let intervalDurationSeconds {
                let duration = time(intervalDurationSeconds)
                details.append(spoken ? "\(numIntervals) intervals of \(duration)" : "\(numIntervals) × \(duration)")
            }
        }
        if numSets > 1 {
            details.append("\(numSets) sets")
            let rest = restDurationSeconds ?? 0
            details.append(rest == 0 ? "No rest" : "\(time(rest)) rest")
        }
        return details.joined(separator: spoken ? ", " : " · ")
    }
}

/// ViewModel for timer selection screen
/// Manages configuration loading and persistence
final class TimerSelectionViewModel: ObservableObject {
    // MARK: - Callbacks

    private let onSelectTimer: (TimerType) -> Void
    private let onNavigateToHistory: () -> Void

    // MARK: - Configuration Storage

    private let userDefaults: UserDefaults
    private let configKeyPrefix = "LastUsedConfig"

    // MARK: - Initialization

    init(
        onSelectTimer: @escaping (TimerType) -> Void,
        onNavigateToHistory: @escaping () -> Void,
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults
        self.onSelectTimer = onSelectTimer
        self.onNavigateToHistory = onNavigateToHistory
    }

    // MARK: - Public Methods

    /// Load saved or default configuration for a timer type
    func configuration(for timerType: TimerType) -> TimerConfiguration {
        let key = "\(configKeyPrefix).\(timerType.rawValue)"

        // Try loading saved configuration
        if let data = userDefaults.data(forKey: key),
           let config = try? JSONDecoder().decode(TimerConfiguration.self, from: data),
           config.timerType == timerType, config.isUsable {
            return config
        }

        // Fallback to default configuration
        return TimerConfiguration.defaultConfiguration(for: timerType)
    }

    /// Save configuration for future use
    func saveConfiguration(_ config: TimerConfiguration) {
        let key = "\(configKeyPrefix).\(config.timerType.rawValue)"

        if config.isUsable, let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: key)
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
