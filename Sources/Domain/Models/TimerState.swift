import Foundation

public enum TimerState: String, Codable {
    case idle
    case countdown
    case countdownPaused
    case running
    case paused
    case resting
    case finished
}

public struct WorkoutState: Codable {
    let id: UUID
    let configuration: TimerConfiguration
    var state: TimerState
    var startTimestamp: Date
    var lastUpdateTimestamp: Date
    var elapsedSeconds: Double
    var accumulatedPausedSeconds: Double
    var currentSet: Int
    var currentInterval: Int?
    var repCount: Int
    var roundCount: Int

    public init(
        id: UUID = UUID(),
        configuration: TimerConfiguration,
        state: TimerState = .idle,
        startTimestamp: Date = Date(),
        lastUpdateTimestamp: Date = Date(),
        elapsedSeconds: Double = 0,
        accumulatedPausedSeconds: Double = 0,
        currentSet: Int = 1,
        currentInterval: Int? = nil,
        repCount: Int = 0,
        roundCount: Int = 0
    ) {
        self.id = id
        self.configuration = configuration
        self.state = state
        self.startTimestamp = startTimestamp
        self.lastUpdateTimestamp = lastUpdateTimestamp
        self.elapsedSeconds = elapsedSeconds
        self.accumulatedPausedSeconds = accumulatedPausedSeconds
        self.currentSet = currentSet
        self.currentInterval = currentInterval
        self.repCount = repCount
        self.roundCount = roundCount
    }
}
