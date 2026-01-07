import Foundation

// MARK: - Workout Summary Data
/// Contains all data needed to display workout summary
public struct WorkoutSummaryData: Equatable, Identifiable {
    public let id: UUID
    public let configuration: TimerConfiguration
    public let duration: TimeInterval
    public let repCount: Int
    public let roundCount: Int
    public let wasCompleted: Bool
    public let roundSplits: [[RoundSplitDisplay]]
    public let setDurations: [SetDuration]
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        configuration: TimerConfiguration,
        duration: TimeInterval,
        repCount: Int,
        roundCount: Int,
        wasCompleted: Bool,
        roundSplits: [[RoundSplitDisplay]],
        setDurations: [SetDuration] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.configuration = configuration
        self.duration = duration
        self.repCount = repCount
        self.roundCount = roundCount
        self.wasCompleted = wasCompleted
        self.roundSplits = roundSplits
        self.setDurations = setDurations
        self.timestamp = timestamp
    }
}

// MARK: - WorkoutSummaryDisplayData Conformance
extension WorkoutSummaryData: WorkoutSummaryDisplayData {
    public var timerType: String? {
        configuration.timerType.rawValue
    }

    public var totalDurationSeconds: Double {
        duration
    }

    public var date: Date? {
        timestamp
    }

    public var roundSplitSets: [[WorkoutRoundSplit]] {
        roundSplits.map { setRounds in
            setRounds.map { roundDisplay in
                WorkoutRoundSplit(
                    id: UUID(),
                    roundNumber: roundDisplay.roundNumber,
                    splitTime: roundDisplay.splitTime
                )
            }
        }
    }

    public var setDurationDetails: [SetDuration] {
        setDurations
    }
}
