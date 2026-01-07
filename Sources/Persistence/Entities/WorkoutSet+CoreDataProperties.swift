import Foundation
import CoreData

extension WorkoutSet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSet> {
        return NSFetchRequest<WorkoutSet>(entityName: "WorkoutSet")
    }

    @NSManaged public var completedAt: Date?
    @NSManaged public var durationSeconds: Double
    @NSManaged public var id: UUID?
    @NSManaged public var setNumber: Int32
    @NSManaged public var startedAt: Date?
    @NSManaged public var wasCompleted: Bool
    @NSManaged public var roundSplits: NSOrderedSet?
    @NSManaged public var workout: Workout?

}

// MARK: Generated accessors for roundSplits
extension WorkoutSet {

    @objc(insertObject:inRoundSplitsAtIndex:)
    @NSManaged public func insertIntoRoundSplits(_ value: RoundSplit, at idx: Int)

    @objc(removeObjectFromRoundSplitsAtIndex:)
    @NSManaged public func removeFromRoundSplits(at idx: Int)

    @objc(insertRoundSplits:atIndexes:)
    @NSManaged public func insertIntoRoundSplits(_ values: [RoundSplit], at indexes: NSIndexSet)

    @objc(removeRoundSplitsAtIndexes:)
    @NSManaged public func removeFromRoundSplits(at indexes: NSIndexSet)

    @objc(replaceObjectInRoundSplitsAtIndex:withObject:)
    @NSManaged public func replaceRoundSplits(at idx: Int, with value: RoundSplit)

    @objc(replaceRoundSplitsAtIndexes:withRoundSplits:)
    @NSManaged public func replaceRoundSplits(at indexes: NSIndexSet, with values: [RoundSplit])

    @objc(addRoundSplitsObject:)
    @NSManaged public func addToRoundSplits(_ value: RoundSplit)

    @objc(removeRoundSplitsObject:)
    @NSManaged public func removeFromRoundSplits(_ value: RoundSplit)

    @objc(addRoundSplits:)
    @NSManaged public func addToRoundSplits(_ values: NSOrderedSet)

    @objc(removeRoundSplits:)
    @NSManaged public func removeFromRoundSplits(_ values: NSOrderedSet)

}

extension WorkoutSet : Identifiable {

}
