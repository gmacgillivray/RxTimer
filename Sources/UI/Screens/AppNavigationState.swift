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
