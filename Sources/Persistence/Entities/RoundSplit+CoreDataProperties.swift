import Foundation
import CoreData

extension RoundSplit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RoundSplit> {
        return NSFetchRequest<RoundSplit>(entityName: "RoundSplit")
    }

    @NSManaged public var cumulativeTime: Double
    @NSManaged public var id: UUID?
    @NSManaged public var roundNumber: Int16
    @NSManaged public var splitTime: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var workoutSet: WorkoutSet?

}

extension RoundSplit : Identifiable {

}
