import Foundation

// MARK: - Navigation State (Single Source of Truth)
/// Represents all possible states of the app's main navigation
enum AppNavigationState: Equatable {
    /// Home screen - showing timer selection (empty state)
    case home

    /// Configuring a timer before starting workout
    case configuration(TimerType)

    /// Active workout in progress
    case activeWorkout(TimerConfiguration, restoredState: WorkoutState?)

    /// Showing workout summary after completion
    case summary(WorkoutSummaryData)

    /// Viewing workout history list
    case history

    /// Viewing specific workout detail from history
    case historyDetail(id: UUID)

    static func == (lhs: AppNavigationState, rhs: AppNavigationState) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home):
            return true
        case (.configuration(let lhsType), .configuration(let rhsType)):
            return lhsType == rhsType
        case (.activeWorkout(let lhsConfig, _), .activeWorkout(let rhsConfig, _)):
            return lhsConfig.timerType == rhsConfig.timerType
        case (.summary(let lhsData), .summary(let rhsData)):
            return lhsData == rhsData
        case (.history, .history):
            return true
        case (.historyDetail(let lhsID), .historyDetail(let rhsID)):
            return lhsID == rhsID
        default:
            return false
        }
    }
}

// MARK: - Workout Summary Data
/// Contains all data needed to display workout summary
struct WorkoutSummaryData: Equatable, Identifiable {
    let id: UUID
    let configuration: TimerConfiguration
    let duration: TimeInterval
    let repCount: Int
    let roundCount: Int
    let wasCompleted: Bool
    let roundSplits: [[RoundSplitDisplay]]
    let setDurations: [SetDuration]
    let timestamp: Date

    init(
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
    var timerType: String? {
        configuration.timerType.rawValue
    }

    var totalDurationSeconds: Double {
        duration
    }

    var date: Date? {
        timestamp
    }

    var roundSplitSets: [[WorkoutRoundSplit]] {
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

    var setDurationDetails: [SetDuration] {
        setDurations
    }
}
