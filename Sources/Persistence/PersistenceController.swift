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

        let workout = NSEntityDescription.insertNewObject(forEntityName: "Workout", into: context)
        workout.setValue(workoutState.id, forKey: "id")
        workout.setValue(workoutState.startTimestamp, forKey: "timestamp")
        workout.setValue(wasCompleted ? Date() : nil, forKey: "completedAt")
        workout.setValue(workoutState.configuration.timerType.rawValue, forKey: "timerType")
        workout.setValue(workoutState.elapsedSeconds, forKey: "totalDurationSeconds")
        workout.setValue(wasCompleted, forKey: "wasCompleted")
        workout.setValue(nil, forKey: "notes")

        // Create configuration
        let config = NSEntityDescription.insertNewObject(forEntityName: "WorkoutConfiguration", into: context)
        config.setValue(UUID(), forKey: "id")
        config.setValue(Int32(workoutState.configuration.durationSeconds ?? 0), forKey: "durationSeconds")
        config.setValue(Int32(workoutState.configuration.timeCapSeconds ?? 0), forKey: "timeCapSeconds")
        config.setValue(Int32(workoutState.configuration.numIntervals ?? 0), forKey: "numIntervals")
        config.setValue(Int32(workoutState.configuration.intervalDurationSeconds ?? 0), forKey: "intervalDurationSeconds")
        config.setValue(Int32(workoutState.configuration.numSets), forKey: "numSets")
        config.setValue(Int32(workoutState.configuration.restDurationSeconds ?? 0), forKey: "restDurationSeconds")
        workout.setValue(config, forKey: "configuration")

        // Create WorkoutSet entities with round splits
        for (setIndex, setRounds) in roundSplits.enumerated() {
            let workoutSet = NSEntityDescription.insertNewObject(forEntityName: "WorkoutSet", into: context)
            workoutSet.setValue(UUID(), forKey: "id")
            workoutSet.setValue(Int32(setIndex + 1), forKey: "setNumber")
            workoutSet.setValue(workoutState.startTimestamp, forKey: "startedAt") // Approximate
            workoutSet.setValue(wasCompleted ? Date() : nil, forKey: "completedAt")
            workoutSet.setValue(wasCompleted, forKey: "wasCompleted")

            // Calculate set duration from rounds
            if let lastRound = setRounds.last {
                workoutSet.setValue(lastRound.cumulativeTime, forKey: "durationSeconds")
            } else {
                workoutSet.setValue(0, forKey: "durationSeconds")
            }

            workoutSet.setValue(workout, forKey: "workout")

            // Create RoundSplit entities for this set
            for roundInfo in setRounds {
                let roundSplit = NSEntityDescription.insertNewObject(forEntityName: "RoundSplit", into: context)
                roundSplit.setValue(UUID(), forKey: "id")
                roundSplit.setValue(Int16(roundInfo.roundNumber), forKey: "roundNumber")
                roundSplit.setValue(roundInfo.splitTime, forKey: "splitTime")
                roundSplit.setValue(roundInfo.cumulativeTime, forKey: "cumulativeTime")
                roundSplit.setValue(roundInfo.timestamp, forKey: "timestamp")
                roundSplit.setValue(workoutSet, forKey: "workoutSet")
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save workout: \(error)")
        }
    }

    // MARK: - Fetch Workouts
    func fetchAllWorkouts() -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Workout")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch workouts: \(error)")
            return []
        }
    }

    // MARK: - Delete Workout
    func deleteWorkout(_ workout: NSManagedObject) {
        let context = container.viewContext
        context.delete(workout)

        do {
            try context.save()
        } catch {
            print("Failed to delete workout: \(error)")
        }
    }
}
