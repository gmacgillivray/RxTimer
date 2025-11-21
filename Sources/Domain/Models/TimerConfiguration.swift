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

// MARK: - Quick Start Defaults
extension TimerConfiguration {
    /// Returns default configuration for Quick Start feature
    static func defaultQuickStart(for timerType: TimerType) -> TimerConfiguration {
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

    /// Returns accessibility description for VoiceOver
    func quickStartAccessibilityDescription() -> String {
        switch timerType {
        case .amrap:
            let minutes = (durationSeconds ?? 600) / 60
            return "Quick Start AMRAP, \(minutes) minutes"
        case .emom:
            let intervals = numIntervals ?? 10
            let seconds = intervalDurationSeconds ?? 60
            return "Quick Start EMOM, \(intervals) intervals of \(seconds) seconds"
        case .forTime:
            if let cap = timeCapSeconds {
                let minutes = cap / 60
                return "Quick Start For Time, \(minutes) minute cap"
            } else {
                return "Quick Start For Time, no time cap"
            }
        }
    }
}

// MARK: - Configuration Provider Protocol
/// Protocol for providing timer configurations (supports testing and flexibility)
protocol ConfigurationProvider {
    func quickStartConfiguration(for timerType: TimerType) -> TimerConfiguration
    func saveConfiguration(_ config: TimerConfiguration)
}

extension ConfigurationProvider {
    /// Gets smart default configuration: last used if available, otherwise default
    func quickStartConfiguration(for timerType: TimerType) -> TimerConfiguration {
        // Try to load last used configuration from UserDefaults
        let key = "QuickStart.LastConfig.\(timerType.rawValue)"
        if let data = UserDefaults.standard.data(forKey: key),
           let config = try? JSONDecoder().decode(TimerConfiguration.self, from: data) {
            return config
        }

        // Fallback to defaults
        return TimerConfiguration.defaultQuickStart(for: timerType)
    }

    /// Saves configuration for future Quick Start usage
    func saveConfiguration(_ config: TimerConfiguration) {
        let key = "QuickStart.LastConfig.\(config.timerType.rawValue)"
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
