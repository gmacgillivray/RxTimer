import Foundation

final class RoundTracker {
    // MARK: - Properties
    private(set) var currentSetRounds: [RoundSplitData] = []
    private(set) var allRoundSplits: [[RoundSplitData]]
    private(set) var lastRoundCompletionTime: TimeInterval = 0.0
    private(set) var lastRoundSplitTime: TimeInterval?
    private(set) var roundCount: Int = 0

    // MARK: - Initialization
    init(numSets: Int, restoredState: WorkoutState? = nil) {
        self.allRoundSplits = restoredState?.progress?.completedRoundSplits
            ?? Array(repeating: [], count: numSets)
        self.currentSetRounds = restoredState?.progress?.currentSetRounds ?? []
        self.roundCount = restoredState?.roundCount ?? 0
        self.lastRoundCompletionTime = currentSetRounds.last?.cumulativeTime ?? 0
        self.lastRoundSplitTime = currentSetRounds.last?.splitTime
    }

    // MARK: - Round Operations

    /// Complete the current round and return the round split data
    @discardableResult
    func completeRound(currentElapsed: TimeInterval) -> RoundSplitData {
        let splitTime = currentElapsed - lastRoundCompletionTime
        let roundNumber = roundCount + 1

        let roundSplit = RoundSplitData(
            roundNumber: roundNumber,
            splitTime: splitTime,
            cumulativeTime: currentElapsed,
            timestamp: Date()
        )

        currentSetRounds.append(roundSplit)
        roundCount = roundNumber
        lastRoundSplitTime = splitTime
        lastRoundCompletionTime = currentElapsed

        return roundSplit
    }

    /// Complete the final round (e.g., when workout finishes) if meaningful time has elapsed
    func completeFinalRound(currentElapsed: TimeInterval, currentSet: Int) {
        let splitTime = currentElapsed - lastRoundCompletionTime

        if splitTime > 0.1 {
            let roundNumber = roundCount + 1
            let roundSplit = RoundSplitData(
                roundNumber: roundNumber,
                splitTime: splitTime,
                cumulativeTime: currentElapsed,
                timestamp: Date()
            )
            currentSetRounds.append(roundSplit)
        }

        // Save current set rounds
        if currentSet > 0 && currentSet <= allRoundSplits.count {
            allRoundSplits[currentSet - 1] = currentSetRounds
        }
    }

    /// Save current set rounds when a set completes
    func saveCurrentSetRounds(currentSet: Int) {
        if currentSet > 0 && currentSet <= allRoundSplits.count {
            allRoundSplits[currentSet - 1] = currentSetRounds
        }
    }

    /// Undo the last completed round, returning true if successful
    @discardableResult
    func undoLastRound() -> Bool {
        guard !currentSetRounds.isEmpty else { return false }
        currentSetRounds.removeLast()
        roundCount -= 1

        if let lastRound = currentSetRounds.last {
            lastRoundCompletionTime = lastRound.cumulativeTime
            lastRoundSplitTime = lastRound.splitTime
        } else {
            lastRoundCompletionTime = 0.0
            lastRoundSplitTime = nil
        }

        return true
    }

    /// Reset for a new set (called on rest start)
    func resetForNewSet() {
        currentSetRounds = []
        roundCount = 0
        lastRoundCompletionTime = 0.0
        lastRoundSplitTime = nil
    }

    /// Reset all round tracking (called on workout reset)
    func resetAll(numSets: Int) {
        currentSetRounds = []
        allRoundSplits = Array(repeating: [], count: numSets)
        lastRoundCompletionTime = 0.0
        lastRoundSplitTime = nil
        roundCount = 0
    }

    /// Get the elapsed time for the current (in-progress) round
    func getCurrentRoundElapsed(currentElapsed: TimeInterval) -> TimeInterval {
        currentElapsed - lastRoundCompletionTime
    }
}
