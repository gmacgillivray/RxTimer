import XCTest
@testable import WorkoutTimer
import CoreData

final class PropertyCheckTests: XCTestCase {
    func testWorkoutProperties() {
        // We can't easily instantiate Workout without a context, but we can check usage via compiler
        let workout: Workout! = nil 
        
        // This line attempts to treat wasCompleted as a Bool. 
        // If it's NSNumber? or Bool?, this should fail compilation or produce specific error.
        let isCompleted: Bool = workout.wasCompleted
        
        if isCompleted {
            print("Completed")
        }
    }
}
