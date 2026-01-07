import Foundation
import CoreData

extension WorkoutConfiguration {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutConfiguration> {
        return NSFetchRequest<WorkoutConfiguration>(entityName: "WorkoutConfiguration")
    }

    @NSManaged public var durationSeconds: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var intervalDurationSeconds: Int32
    @NSManaged public var numIntervals: Int32
    @NSManaged public var numSets: Int32
    @NSManaged public var restDurationSeconds: Int32
    @NSManaged public var timeCapSeconds: Int32
    @NSManaged public var workout: Workout?

}

extension WorkoutConfiguration : Identifiable {

}
