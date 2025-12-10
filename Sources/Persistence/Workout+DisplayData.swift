import Foundation
import CoreData

extension Workout: WorkoutSummaryDisplayData {
    // timerType and totalDurationSeconds already exist on Workout entity

    var date: Date? {
        self.timestamp
    }

    var roundSplitSets: [[WorkoutRoundSplit]] {
        guard let setsArray = sets?.array as? [WorkoutSet] else { return [] }

        return setsArray.map { workoutSet in
            guard let roundSplitsArray = workoutSet.roundSplits?.array as? [RoundSplit] else {
                return []
            }

            return roundSplitsArray
                .sorted { $0.roundNumber < $1.roundNumber }
                .map { split in
                    WorkoutRoundSplit(
                        id: split.id ?? UUID(),
                        roundNumber: Int(split.roundNumber),
                        splitTime: split.splitTime
                    )
                }
        }
    }

    var setDurationDetails: [SetDuration] {
        // For persisted workouts (before this feature), return empty array
        // Future enhancement: persist SetDuration data to Core Data
        return []
    }
}
