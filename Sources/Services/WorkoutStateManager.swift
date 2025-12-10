import Foundation
import Combine

final class WorkoutStateManager {
    static let shared = WorkoutStateManager()

    private let userDefaults = UserDefaults.standard
    private let stateKey = "com.workoutTimer.activeWorkoutState"
    private let expiryDuration: TimeInterval = 3600 // 1 hour

    private init() {}

    // MARK: - Save State
    func saveState(_ state: WorkoutState) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: stateKey)
            userDefaults.synchronize()
        } catch {
            print("Failed to save workout state: \(error)")
        }
    }

    // MARK: - Load State
    func loadState() -> WorkoutState? {
        guard let data = userDefaults.data(forKey: stateKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let state = try decoder.decode(WorkoutState.self, from: data)

            // Don't restore countdown states - they're transient and meaningless after app restart
            if state.state == .countdown {
                clearState()
                return nil
            }

            // Check if state has expired (older than 1 hour)
            let age = Date().timeIntervalSince(state.lastUpdateTimestamp)
            if age >= expiryDuration {
                // State expired - save as incomplete and clear
                saveExpiredWorkoutAsIncomplete(state)
                clearState()
                return nil
            }

            return state
        } catch {
            print("Failed to load workout state: \(error)")
            // Clear corrupted state
            clearState()
            return nil
        }
    }

    // MARK: - Clear State
    func clearState() {
        userDefaults.removeObject(forKey: stateKey)
        userDefaults.synchronize()
    }

    // MARK: - Private Methods
    private func saveExpiredWorkoutAsIncomplete(_ state: WorkoutState) {
        // Save the workout as incomplete to Core Data
        PersistenceController.shared.saveWorkout(state, wasCompleted: false)
    }
}
