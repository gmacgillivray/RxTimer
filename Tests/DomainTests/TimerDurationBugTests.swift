
import XCTest
@testable import RxTimer

final class TimerDurationBugTests: XCTestCase {
    
    // MARK: - Bug Reproduction Tests
    
    // Test Case: `testTotalDurationWithMultipleSets`
    //    - Configure a workout with 2 sets.
    //    - Start timer.
    //    - Advance time by 10s.
    //    - Complete set 1.
    //    - Verify `getTotalDuration()` is 10s.
    //    - Start rest (if applicable) or next set.
    //    - Advance time by 10s.
    //    - Complete set 2 (finish).
    //    - Verify `getTotalDuration()` is 20s (not 30s).
    func testTotalDurationWithMultipleSets() {
        // Setup configuration with 2 sets
        let config = TimerConfiguration(
            timerType: .amrap,
            durationSeconds: 60, // Arbitrary long duration
            numSets: 2,
            restDurationSeconds: 0 // No rest to simplify
        )
        let engine = TimerEngine(configuration: config)
        
        // Start Timer (Set 1)
        engine.start()
        
        // Advance time by 10s
        let initialExpectation = expectation(description: "Wait for 10s simulation")
        // We can't easily "advance time" directly without access to internal startWallTime mocks in this black-box test,
        // so we'll wait for a short duration instead.
        // Wait 1 second for Set 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            // Check current elapsed for Set 1 (should be ~1s)
            let elapsedSet1 = engine.getCurrentElapsed()
            XCTAssertGreaterThanOrEqual(elapsedSet1, 0.9)
            XCTAssertLessThanOrEqual(elapsedSet1, 1.5)
            
            // Complete Set 1
            // This should:
            // 1. Add current ~1s to completedSetDurations
            // 2. Reset accumulated (BUG: It doesn't!)
            // 3. Start Set 2
            engine.completeSet()
            
            // Verify verification: Check reset accumulated
            XCTAssertEqual(engine.currentSetNumber, 2, "Should be on Set 2")
            
            // Advance time by 1s for Set 2
             DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                 
                 // Finish Workout (Complete Set 2)
                 engine.completeSet() // Finishes workout
                 
                 // Get Total Duration
                 let totalDuration = engine.getTotalDuration()
                 
                 // Expected: ~1s (Set 1) + ~1s (Set 2) = ~2s
                 // Bug: ~1s (Set 1) + (~1s from Set 1 + ~1s from Set 2) = ~3s
                 
                 print("DEBUG: Total Duration: \(totalDuration)")
                 
                 // Allow some tolerance
                 XCTAssertLessThan(totalDuration, 2.5, "Total duration is incorrectly double-counting the first set duration!")
                 XCTAssertGreaterThan(totalDuration, 1.8, "Total duration should include both sets")
                 
                 initialExpectation.fulfill()
             }
        }
        
        wait(for: [initialExpectation], timeout: 5.0)
    }

    func testTotalDurationWithRest() {
        // Test with rest periods to ensure `startRest` also handles reset correctly
         let config = TimerConfiguration(
             timerType: .amrap,
             durationSeconds: 60,
             numSets: 2,
             restDurationSeconds: 1 // 1s rest
         )
         let engine = TimerEngine(configuration: config)
         
         // Start Timer (Set 1)
         engine.start()
         
         // Run Set 1 for 1s
         let expectation = expectation(description: "Run Set 1")
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
             // Complete Set 1 -> Start Rest
             engine.completeSet()
             
             XCTAssertEqual(engine.state, .resting)
             
             // Run Rest for 0.5s (skipping rest for speed, or wait)
             // Let's just skip rest to trigger next set start logic
             engine.skipRest()
             
             XCTAssertEqual(engine.currentSetNumber, 2)
             
             // Run Set 2 for 1s
             DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                 engine.completeSet() // Finish
                 
                 let totalDuration = engine.getTotalDuration()
                 // Expected: ~1s (Set 1) + ~0s (Rest) + ~1s (Set 2) = ~2s
                 
                 XCTAssertLessThan(totalDuration, 2.8, "Total duration double counted with rest")
                 
                 expectation.fulfill()
             }
         }
         
         wait(for: [expectation], timeout: 5.0)
    }
}
