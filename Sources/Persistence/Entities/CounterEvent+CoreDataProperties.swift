import Foundation
import CoreData

extension CounterEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CounterEvent> {
        return NSFetchRequest<CounterEvent>(entityName: "CounterEvent")
    }

    @NSManaged public var counterType: String?
    @NSManaged public var elapsedSeconds: Double
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var value: Int32
    @NSManaged public var workout: Workout?

}

extension CounterEvent : Identifiable {

}
