import Foundation

public struct RoundSplitData: Equatable {
    public let roundNumber: Int
    public let splitTime: TimeInterval
    public let cumulativeTime: TimeInterval
    public let timestamp: Date

    public init(roundNumber: Int, splitTime: TimeInterval, cumulativeTime: TimeInterval, timestamp: Date) {
        self.roundNumber = roundNumber
        self.splitTime = splitTime
        self.cumulativeTime = cumulativeTime
        self.timestamp = timestamp
    }
}
