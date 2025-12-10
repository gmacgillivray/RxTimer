import Foundation

public struct TimerConfiguration: Codable, Equatable {
    let timerType: TimerType

    // For Time specific
    var timeCapSeconds: Int?

    // AMRAP specific
    var durationSeconds: Int?

    // EMOM specific
    var numIntervals: Int?
    var intervalDurationSeconds: Int?

    // Multi-set support (all types)
    var numSets: Int
    var restDurationSeconds: Int?

    public init(
        timerType: TimerType,
        timeCapSeconds: Int? = nil,
        durationSeconds: Int? = nil,
        numIntervals: Int? = nil,
        intervalDurationSeconds: Int? = nil,
        numSets: Int = 1,
        restDurationSeconds: Int? = nil
    ) {
        self.timerType = timerType
        self.timeCapSeconds = timeCapSeconds
        self.durationSeconds = durationSeconds
        self.numIntervals = numIntervals
        self.intervalDurationSeconds = intervalDurationSeconds
        self.numSets = numSets
        self.restDurationSeconds = restDurationSeconds
    }

    var totalDurationSeconds: Int? {
        switch timerType {
        case .forTime:
            return timeCapSeconds
        case .amrap:
            return durationSeconds
        case .emom:
            guard let intervals = numIntervals,
                  let intervalDuration = intervalDurationSeconds else { return nil }
            return intervals * intervalDuration
        }
    }
}

// MARK: - Configuration Defaults
extension TimerConfiguration {
    /// Returns default configuration for a timer type
    static func defaultConfiguration(for timerType: TimerType) -> TimerConfiguration {
        switch timerType {
        case .amrap:
            return TimerConfiguration(
                timerType: .amrap,
                durationSeconds: 600, // 10 minutes
                numSets: 1,
                restDurationSeconds: nil
            )
        case .emom:
            return TimerConfiguration(
                timerType: .emom,
                numIntervals: 10,
                intervalDurationSeconds: 60, // 60 seconds
                numSets: 1,
                restDurationSeconds: nil
            )
        case .forTime:
            return TimerConfiguration(
                timerType: .forTime,
                timeCapSeconds: nil, // No cap
                numSets: 1,
                restDurationSeconds: nil
            )
        }
    }
}

// MARK: - Configuration Provider Protocol
/// Protocol for providing timer configurations (supports testing and flexibility)
protocol ConfigurationProvider {
    func configuration(for timerType: TimerType) -> TimerConfiguration
    func saveConfiguration(_ config: TimerConfiguration)
}

extension ConfigurationProvider {
    /// Gets last used configuration if available, otherwise returns default
    func configuration(for timerType: TimerType) -> TimerConfiguration {
        // Try to load last used configuration from UserDefaults
        let key = "LastUsedConfig.\(timerType.rawValue)"
        if let data = UserDefaults.standard.data(forKey: key),
           let config = try? JSONDecoder().decode(TimerConfiguration.self, from: data) {
            return config
        }

        // Fallback to defaults
        return TimerConfiguration.defaultConfiguration(for: timerType)
    }

    /// Saves configuration for future use
    func saveConfiguration(_ config: TimerConfiguration) {
        let key = "LastUsedConfig.\(config.timerType.rawValue)"
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
