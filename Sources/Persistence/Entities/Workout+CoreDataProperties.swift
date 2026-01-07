import Foundation
import CoreData

extension Workout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workout> {
        return NSFetchRequest<Workout>(entityName: "Workout")
    }

    @NSManaged public var completedAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var timerType: String?
    @NSManaged public var totalDurationSeconds: Double
    @NSManaged public var wasCompleted: Bool
    @NSManaged public var configuration: WorkoutConfiguration?
    @NSManaged public var counterEvents: NSOrderedSet?
    @NSManaged public var sets: NSOrderedSet?

}

// MARK: Generated accessors for counterEvents
extension Workout {

    @objc(insertObject:inCounterEventsAtIndex:)
    @NSManaged public func insertIntoCounterEvents(_ value: CounterEvent, at idx: Int)

    @objc(removeObjectFromCounterEventsAtIndex:)
    @NSManaged public func removeFromCounterEvents(at idx: Int)

    @objc(insertCounterEvents:atIndexes:)
    @NSManaged public func insertIntoCounterEvents(_ values: [CounterEvent], at indexes: NSIndexSet)

    @objc(removeCounterEventsAtIndexes:)
    @NSManaged public func removeFromCounterEvents(at indexes: NSIndexSet)

    @objc(replaceObjectInCounterEventsAtIndex:withObject:)
    @NSManaged public func replaceCounterEvents(at idx: Int, with value: CounterEvent)

    @objc(replaceCounterEventsAtIndexes:withCounterEvents:)
    @NSManaged public func replaceCounterEvents(at indexes: NSIndexSet, with values: [CounterEvent])

    @objc(addCounterEventsObject:)
    @NSManaged public func addToCounterEvents(_ value: CounterEvent)

    @objc(removeCounterEventsObject:)
    @NSManaged public func removeFromCounterEvents(_ value: CounterEvent)

    @objc(addCounterEvents:)
    @NSManaged public func addToCounterEvents(_ values: NSOrderedSet)

    @objc(removeCounterEvents:)
    @NSManaged public func removeFromCounterEvents(_ values: NSOrderedSet)

}

// MARK: Generated accessors for sets
extension Workout {

    @objc(insertObject:inSetsAtIndex:)
    @NSManaged public func insertIntoSets(_ value: WorkoutSet, at idx: Int)

    @objc(removeObjectFromSetsAtIndex:)
    @NSManaged public func removeFromSets(at idx: Int)

    @objc(insertSets:atIndexes:)
    @NSManaged public func insertIntoSets(_ values: [WorkoutSet], at indexes: NSIndexSet)

    @objc(removeSetsAtIndexes:)
    @NSManaged public func removeFromSets(at indexes: NSIndexSet)

    @objc(replaceObjectInSetsAtIndex:withObject:)
    @NSManaged public func replaceSets(at idx: Int, with value: WorkoutSet)

    @objc(replaceSetsAtIndexes:withSets:)
    @NSManaged public func replaceSets(at indexes: NSIndexSet, with values: [WorkoutSet])

    @objc(addSetsObject:)
    @NSManaged public func addToSets(_ value: WorkoutSet)

    @objc(removeSetsObject:)
    @NSManaged public func removeFromSets(_ value: WorkoutSet)

    @objc(addSets:)
    @NSManaged public func addToSets(_ values: NSOrderedSet)

    @objc(removeSets:)
    @NSManaged public func removeFromSets(_ values: NSOrderedSet)

}

extension Workout : Identifiable {

}
