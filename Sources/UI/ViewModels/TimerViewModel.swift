import Foundation
import Combine
import UIKit

final class TimerViewModel: ObservableObject, TimerEngineDelegate {
    // MARK: - Published Properties
    @Published var timeText: String = "00:00"
    @Published var elapsedTimeText: String = "00:00" // For AMRAP: shows elapsed time
    @Published var restTimeText: String = "00:00"
    @Published var currentRoundTimeText: String = "00:00"
    @Published var state: TimerState = .idle
    @Published var repCount: Int = 0
    @Published var roundCount: Int = 0
    @Published var currentSet: Int = 1
    @Published var currentInterval: Int = 1
    @Published var showCounterButton: Bool = true // Always show round counter

    // MARK: - Exposed Configuration (read-only)
    var timerType: TimerType { timerConfiguration.timerType }
    var numSets: Int { timerConfiguration.numSets }
    var numIntervals: Int { timerConfiguration.numIntervals ?? 0 }
    var timerTypeDisplayName: String { timerConfiguration.timerType.displayName }
    var configuration: TimerConfiguration { timerConfiguration }
    var allRounds: [[RoundSplitData]] { allRoundSplits }

    func getCurrentElapsed() -> TimeInterval {
        return engine.getCurrentElapsed()
    }

    func getTotalDuration() -> TimeInterval {
        return engine.getTotalDuration()
    }

    func getSetDurations() -> [SetDuration] {
        return engine.setDurations
    }

    // MARK: - Properties
    private let timerConfiguration: TimerConfiguration
    private let engine: TimerEngine
    private let backgroundAudio = BackgroundAudioService.shared
    private let haptics = HapticService.shared
    private let audio = AudioService.shared
    private let notifications = NotificationService.shared
    private let stateManager = WorkoutStateManager.shared
    private var workoutState: WorkoutState
    private var cancellables = Set<AnyCancellable>()
    private var autosaveTimer: AnyCancellable?

    // MARK: - Round Tracking
    struct RoundSplitData {
        let roundNumber: Int
        let splitTime: TimeInterval
        let cumulativeTime: TimeInterval
        let timestamp: Date
    }
    private var currentSetRounds: [RoundSplitData] = []
    private var allRoundSplits: [[RoundSplitData]] = [[]] // Array of arrays, one per set
    private var lastRoundCompletionTime: TimeInterval = 0.0
    private var activeWorkoutStartTime: TimeInterval = 0.0 // Excludes paused/rest time

    // MARK: - Initialization
    init(configuration: TimerConfiguration, restoredState: WorkoutState? = nil) {
        self.timerConfiguration = configuration
        self.engine = TimerEngine(configuration: configuration)

        // Use restored state if available, otherwise create new
        if let restored = restoredState {
            self.workoutState = restored
            self.currentSet = restored.currentSet
            self.repCount = restored.repCount
            self.roundCount = restored.roundCount
            self.currentInterval = restored.currentInterval ?? 1
            self.state = .paused // Always restore as paused per spec

            // Restore time display
            let elapsed = restored.elapsedSeconds
            if configuration.timerType == .amrap, let total = configuration.totalDurationSeconds {
                let remaining = Double(total) - elapsed
                self.timeText = formatTime(max(0, remaining))
                self.elapsedTimeText = formatTime(elapsed)
            } else {
                self.timeText = formatTime(elapsed)
            }
        } else {
            self.workoutState = WorkoutState(configuration: configuration)
            self.currentSet = 1

            // Initialize idle state display based on timer type
            switch configuration.timerType {
            case .amrap:
                // AMRAP: Show configured duration (countdown timer)
                if let total = configuration.totalDurationSeconds {
                    self.timeText = formatTime(Double(total))
                } else {
                    self.timeText = "00:00"
                }
                self.elapsedTimeText = "00:00"

            case .emom:
                // EMOM: Show first interval duration
                if let intervalDuration = configuration.intervalDurationSeconds {
                    self.timeText = formatTime(Double(intervalDuration))
                } else {
                    self.timeText = "00:00"
                }

            case .forTime:
                // For Time: Show 00:00 (counts up from zero)
                self.timeText = "00:00"
            }
        }

        self.engine.delegate = self

        // Initialize round tracking arrays based on number of sets
        self.allRoundSplits = Array(repeating: [], count: configuration.numSets)

        // Setup background/foreground notifications for state saving
        setupLifecycleObservers()
    }

    deinit {
        stopAutosave()
    }

    // MARK: - Timer Actions
    func startTapped() {
        if state == .idle {
            workoutState.startTimestamp = Date()
            workoutState.state = .running
            notifications.scheduleWorkoutNotifications(configuration: timerConfiguration, startTime: Date())
            backgroundAudio.start()
            startAutosave()
        }
        engine.start()
        saveState()
    }

    func pauseTapped() {
        engine.pause()
        backgroundAudio.stop()
        stopAutosave()
        saveState()
    }

    func resumeTapped() {
        engine.resume()
        backgroundAudio.start()
        startAutosave()
        saveState()
    }

    func resetTapped() {
        engine.reset()
        backgroundAudio.stop()
        notifications.cancelAllNotifications()
        backgroundAudio.clearNowPlaying()
        stopAutosave()
        clearSavedState()
        repCount = 0
        roundCount = 0
        currentSet = 1
        currentInterval = 1
        timeText = "00:00"
        currentRoundTimeText = "00:00"

        // Reset round tracking
        currentSetRounds = []
        allRoundSplits = Array(repeating: [], count: timerConfiguration.numSets)
        lastRoundCompletionTime = 0.0
        activeWorkoutStartTime = 0.0
    }

    func finishTapped() {
        // Note: Saving is handled automatically by timerDidChangeState(.finished)
        // when engine.finish() changes the state. Don't save here to avoid duplicates.
        engine.finish()
        backgroundAudio.stop()
        notifications.cancelAllNotifications()
        backgroundAudio.clearNowPlaying()
        stopAutosave()
    }

    func completeSetTapped() {
        // Can only complete set when running
        guard state == .running else { return }

        // Engine will handle:
        // - If not final set: start rest period
        // - If final set: finish workout
        engine.completeSet()

        // State changes and audio/haptics handled by delegate callbacks
    }

    func completeRound() {
        // Can only complete round during active workout (not paused, not resting, not finished)
        guard state == .running else { return }

        let currentTime = engine.getCurrentElapsed()
        let splitTime = currentTime - lastRoundCompletionTime
        let roundNumber = currentSetRounds.count + 1

        let roundSplit = RoundSplitData(
            roundNumber: roundNumber,
            splitTime: splitTime,
            cumulativeTime: currentTime,
            timestamp: Date()
        )

        currentSetRounds.append(roundSplit)
        roundCount = currentSetRounds.count
        lastRoundCompletionTime = currentTime

        // Play haptic feedback
        haptics.trigger(event: "counter_increment")

        // Save state after round completion
        saveState()
    }

    func skipRest() {
        engine.skipRest()
    }

    // MARK: - State Management
    private func setupLifecycleObservers() {
        // Observe app entering background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.saveState()
            }
            .store(in: &cancellables)

        // Observe app entering foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                // Could check for state restoration here if needed
            }
            .store(in: &cancellables)
    }

    private func startAutosave() {
        // Autosave every 5 seconds while running
        autosaveTimer = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.saveState()
            }
    }

    private func stopAutosave() {
        autosaveTimer?.cancel()
        autosaveTimer = nil
    }

    private func saveState() {
        guard state != .idle && state != .finished else { return }

        // Update workout state with current values
        workoutState.state = state
        workoutState.lastUpdateTimestamp = Date()
        workoutState.elapsedSeconds = engine.getCurrentElapsed()
        workoutState.currentSet = currentSet
        workoutState.currentInterval = currentInterval
        workoutState.repCount = repCount
        workoutState.roundCount = roundCount

        // Save to UserDefaults
        stateManager.saveState(workoutState)
    }

    private func clearSavedState() {
        stateManager.clearState()
    }

    // MARK: - Round Tracking Helpers
    private func completeFinalRound() {
        guard state == .running || state == .finished else { return }

        let currentTime = engine.getCurrentElapsed()
        let splitTime = currentTime - lastRoundCompletionTime

        // Only add final round if there's meaningful time elapsed
        if splitTime > 0.1 {
            let roundNumber = currentSetRounds.count + 1
            let roundSplit = RoundSplitData(
                roundNumber: roundNumber,
                splitTime: splitTime,
                cumulativeTime: currentTime,
                timestamp: Date()
            )
            currentSetRounds.append(roundSplit)
        }

        // Save current set rounds to all rounds
        if currentSet > 0 && currentSet <= allRoundSplits.count {
            allRoundSplits[currentSet - 1] = currentSetRounds
        }
    }

    private func getCurrentRoundElapsed() -> TimeInterval {
        guard state == .running else { return 0 }
        let currentTime = engine.getCurrentElapsed()
        return currentTime - lastRoundCompletionTime
    }

    private func saveWorkoutWithRounds(wasCompleted: Bool) {
        // Convert RoundSplitData to PersistenceController.RoundSplitInfo
        let roundSplitsForPersistence: [[PersistenceController.RoundSplitInfo]] = allRoundSplits.map { setRounds in
            setRounds.map { roundData in
                PersistenceController.RoundSplitInfo(
                    roundNumber: roundData.roundNumber,
                    splitTime: roundData.splitTime,
                    cumulativeTime: roundData.cumulativeTime,
                    timestamp: roundData.timestamp
                )
            }
        }

        // Save workout with round splits
        PersistenceController.shared.saveWorkout(
            workoutState,
            wasCompleted: wasCompleted,
            roundSplits: roundSplitsForPersistence
        )
    }

    // MARK: - Timer Engine Delegate
    func timerDidTick(elapsed: TimeInterval, remaining: TimeInterval?) {
        if state == .resting {
            // During rest, show countdown
            restTimeText = formatTime(remaining ?? 0)
            currentRoundTimeText = "00:00" // Don't show during rest
            backgroundAudio.updateNowPlaying(
                timerType: "Rest",
                elapsed: restTimeText,
                set: "Between Sets"
            )
        } else if state == .running {
            // During workout
            if timerConfiguration.timerType == .amrap {
                // AMRAP: Main display shows remaining time, secondary shows elapsed
                if let remaining = remaining {
                    timeText = formatTime(max(0, remaining))
                } else {
                    timeText = formatTime(elapsed)
                }
                elapsedTimeText = formatTime(elapsed)
            } else {
                // Other timers: Show elapsed time
                timeText = formatTime(elapsed)
            }

            // Update current round time
            let currentRoundElapsed = getCurrentRoundElapsed()
            currentRoundTimeText = formatTime(currentRoundElapsed)

            // Update Now Playing
            let setInfo = timerConfiguration.numSets > 1 ? "Set \(currentSet) of \(timerConfiguration.numSets)" : nil
            backgroundAudio.updateNowPlaying(
                timerType: timerConfiguration.timerType.displayName,
                elapsed: timeText,
                set: setInfo
            )

            // Update workout state
            workoutState.elapsedSeconds = elapsed
            workoutState.lastUpdateTimestamp = Date()
        }
    }

    func timerDidEmit(event: String) {
        haptics.trigger(event: event)
        playAudioForEvent(event)

        // Update interval counter for EMOM
        if event == "interval_tick" {
            currentInterval += 1
        }

        // Handle set completion
        if event == "set_complete" {
            // Save current set's rounds before transitioning
            if currentSet > 0 && currentSet <= allRoundSplits.count {
                allRoundSplits[currentSet - 1] = currentSetRounds
            }
        }

        // Handle rest start
        if event == "rest_start" {
            // Reset for next set
            currentSetRounds = []
            roundCount = 0
            lastRoundCompletionTime = 0.0

            // Reset other counters
            if timerConfiguration.timerType == .forTime {
                repCount = 0
            }
            currentInterval = 1
        }

        // Handle new set start (after rest)
        if event == "set_start" {
            // Rounds and counters already reset during rest_start
            // This event is for audio/haptic feedback
        }
    }

    func timerDidChangeState(_ newState: TimerState) {
        self.state = newState
        workoutState.state = newState

        // Sync current set from engine
        currentSet = engine.currentSetNumber

        // Save state on state transitions
        if newState == .resting {
            stopAutosave()
            saveState()
        } else if newState == .running {
            startAutosave()
            saveState()
        }

        if newState == .finished {
            stopAutosave()
            // Complete final round and save workout
            completeFinalRound()
            workoutState.elapsedSeconds = engine.getCurrentElapsed()
            saveWorkoutWithRounds(wasCompleted: true)
            clearSavedState()
        }
    }

    // MARK: - Helpers
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    private func playAudioForEvent(_ event: String) {
        switch event {
        case "start":
            audio.play(sound: "start")
        case "interval_tick":
            audio.play(sound: "tick")
        case "last_minute", "30s_left":
            audio.play(sound: "warn")
        case "countdown_10s":
            audio.play(sound: "beep_1hz")
        case "finish":
            audio.play(sound: "end")
        case "set_complete":
            audio.play(sound: "end") // Set completed
        case "rest_start":
            audio.play(sound: "end") // Rest period starting
        case "set_start":
            audio.play(sound: "start") // New set starting
        default:
            break
        }
    }
}
