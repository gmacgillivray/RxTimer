import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WorkoutTimer")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Round Split Data Structure
    struct RoundSplitInfo {
        let roundNumber: Int
        let splitTime: TimeInterval
        let cumulativeTime: TimeInterval
        let timestamp: Date
    }

    // MARK: - Save Workout
    func saveWorkout(_ workoutState: WorkoutState, wasCompleted: Bool, roundSplits: [[RoundSplitInfo]] = []) {
        let context = container.viewContext

        let workout = Workout(context: context)
        workout.id = workoutState.id
        workout.timestamp = workoutState.startTimestamp
        workout.completedAt = wasCompleted ? Date() : nil
        workout.timerType = workoutState.configuration.timerType.rawValue
        workout.totalDurationSeconds = workoutState.elapsedSeconds
        workout.wasCompleted = wasCompleted
        workout.notes = nil

        // Create configuration
        let config = WorkoutConfiguration(context: context)
        config.id = UUID()
        config.durationSeconds = Int32(workoutState.configuration.durationSeconds ?? 0)
        config.timeCapSeconds = Int32(workoutState.configuration.timeCapSeconds ?? 0)
        config.numIntervals = Int32(workoutState.configuration.numIntervals ?? 0)
        config.intervalDurationSeconds = Int32(workoutState.configuration.intervalDurationSeconds ?? 0)
        config.numSets = Int32(workoutState.configuration.numSets)
        config.restDurationSeconds = Int32(workoutState.configuration.restDurationSeconds ?? 0)
        workout.configuration = config

        // Create WorkoutSet entities with round splits
        for (setIndex, setRounds) in roundSplits.enumerated() {
            let workoutSet = WorkoutSet(context: context)
            workoutSet.id = UUID()
            workoutSet.setNumber = Int32(setIndex + 1)
            workoutSet.startedAt = workoutState.startTimestamp // Approximate
            workoutSet.completedAt = wasCompleted ? Date() : nil
            workoutSet.wasCompleted = wasCompleted

            // Calculate set duration from rounds
            if let lastRound = setRounds.last {
                workoutSet.durationSeconds = lastRound.cumulativeTime
            } else {
                workoutSet.durationSeconds = 0
            }

            workoutSet.workout = workout

            // Create RoundSplit entities for this set
            for roundInfo in setRounds {
                let roundSplit = RoundSplit(context: context)
                roundSplit.id = UUID()
                roundSplit.roundNumber = Int16(roundInfo.roundNumber)
                roundSplit.splitTime = roundInfo.splitTime
                roundSplit.cumulativeTime = roundInfo.cumulativeTime
                roundSplit.timestamp = roundInfo.timestamp
                roundSplit.workoutSet = workoutSet
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save workout: \(error)")
        }
    }

    // MARK: - Fetch Workouts
    func fetchAllWorkouts() -> [Workout] {
        let fetchRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch workouts: \(error)")
            return []
        }
    }

    // MARK: - Delete Workout
    func deleteWorkout(_ workout: Workout) {
        let context = container.viewContext
        context.delete(workout)

        do {
            try context.save()
        } catch {
            print("Failed to delete workout: \(error)")
        }
    }
}
