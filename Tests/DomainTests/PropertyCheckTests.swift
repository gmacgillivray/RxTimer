import XCTest
@testable import WorkoutTimer
import CoreData

final class PropertyCheckTests: XCTestCase {
    func testWorkoutPropertiesExist() {
        // Verify Workout entity properties are accessible via Core Data
        // Use the entity description to confirm wasCompleted exists as a Bool attribute
        let container = NSPersistentContainer(name: "WorkoutTimer")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        let loadExpectation = expectation(description: "Store loaded")
        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load in-memory store: \(error?.localizedDescription ?? "")")
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 2.0)

        let context = container.viewContext
        let workout = NSEntityDescription.insertNewObject(forEntityName: "Workout", into: context)

        // Verify wasCompleted is a Bool (scalar)
        workout.setValue(true, forKey: "wasCompleted")
        let isCompleted = workout.value(forKey: "wasCompleted") as? Bool
        XCTAssertEqual(isCompleted, true, "wasCompleted should be a Bool")
    }
}
