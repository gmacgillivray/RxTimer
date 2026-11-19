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
    @Published var countdownText: String = "10"
    @Published var emomElapsedTimeText: String = "00:00"
    @Published private(set) var result: WorkoutSummaryData?

    // MARK: - Exposed Configuration (read-only)
    var timerType: TimerType { timerConfiguration.timerType }
    var numSets: Int { timerConfiguration.numSets }
    var numIntervals: Int { timerConfiguration.numIntervals ?? 0 }
    var timerTypeDisplayName: String { timerConfiguration.timerType.displayName }
    var configuration: TimerConfiguration { timerConfiguration }
    var allRounds: [[RoundSplitData]] { roundTracker.allRoundSplits }

    /// Progress from 0.0 to 1.0 for timed workouts (AMRAP, EMOM, For Time with cap)
    var progress: Double? {
        guard let total = timerConfiguration.totalDurationSeconds, total > 0 else { return nil }
        let elapsed = engine.getCurrentElapsed()
        return min(1.0, max(0.0, elapsed / Double(total)))
    }

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
    private let audioCoordinator: AudioCoordinator
    private let hapticCoordinator: HapticCoordinator
    private let stateManager: WorkoutStateManager
    private let persistence: PersistenceController
    private let onWorkoutStarted: ((TimerConfiguration) -> Void)?
    private var workoutState: WorkoutState
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Performance: Display Throttling
    private let throttler = DisplayThrottler()

    // MARK: - Round Tracking
    private let roundTracker: RoundTracker

    // MARK: - Last Round Tracking (for display)
    @Published var lastRoundSplitTime: TimeInterval? = nil

    // Computed property for delta (current round vs last round)
    var currentRoundVsLastDelta: TimeInterval? {
        guard let lastSplit = lastRoundSplitTime, state == .running else { return nil }
        let currentRoundElapsed = roundTracker.getCurrentRoundElapsed(currentElapsed: engine.getCurrentElapsed())
        return currentRoundElapsed - lastSplit
    }

    // MARK: - Initialization
    init(
        configuration: TimerConfiguration,
        restoredState: WorkoutState? = nil,
        audioCoordinator: AudioCoordinator = AudioCoordinator(),
        hapticCoordinator: HapticCoordinator = HapticCoordinator(),
        stateManager: WorkoutStateManager = .shared,
        persistence: PersistenceController = .shared,
        engine: TimerEngine? = nil,
        onWorkoutStarted: ((TimerConfiguration) -> Void)? = nil
    ) {
        self.timerConfiguration = configuration
        self.engine = engine ?? TimerEngine(configuration: configuration, restoredState: restoredState)
        self.audioCoordinator = audioCoordinator
        self.hapticCoordinator = hapticCoordinator
        self.stateManager = stateManager
        self.persistence = persistence
        self.onWorkoutStarted = onWorkoutStarted
        self.roundTracker = RoundTracker(numSets: configuration.numSets, restoredState: restoredState)

        // Configure Coordinators
        self.audioCoordinator.configure(timerType: configuration.timerType, numSets: configuration.numSets)

        // Use restored state if available, otherwise create new
        if let restored = restoredState {
            self.workoutState = restored
            self.currentSet = restored.currentSet
            self.repCount = restored.repCount
            self.roundCount = restored.roundCount
            self.lastRoundSplitTime = roundTracker.lastRoundSplitTime
            self.currentInterval = restored.currentInterval ?? 1
            self.state = .paused // Always restore as paused per spec

            // Restore time display
            let elapsed = restored.elapsedSeconds
            if configuration.timerType == .amrap, let total = configuration.totalDurationSeconds {
                let remaining = Double(total) - elapsed
                self.timeText = TimeFormatter.format(max(0, remaining))
                self.elapsedTimeText = TimeFormatter.format(elapsed)
            } else {
                self.timeText = TimeFormatter.format(elapsed)
            }
        } else {
            self.workoutState = WorkoutState(configuration: configuration)
            self.currentSet = 1

            // Initialize idle state display based on timer type
            switch configuration.timerType {
            case .amrap:
                // AMRAP: Show configured duration (countdown timer)
                if let total = configuration.totalDurationSeconds {
                    self.timeText = TimeFormatter.format(Double(total))
                } else {
                    self.timeText = "00:00"
                }
                self.elapsedTimeText = "00:00"

            case .emom:
                // EMOM: Show first interval duration
                if let intervalDuration = configuration.intervalDurationSeconds {
                    self.timeText = TimeFormatter.format(Double(intervalDuration))
                } else {
                    self.timeText = "00:00"
                }

            case .forTime:
                // For Time: Show 00:00 (counts up from zero)
                self.timeText = "00:00"
            }
        }

        self.engine.delegate = self

        // Setup background/foreground notifications for state saving
        setupLifecycleObservers()
    }


    // MARK: - Timer Actions
    func toggleCountdownPause() {
        if state == .countdown {
            engine.pause()
        } else if state == .countdownPaused {
            engine.resume()
        }
    }

    func startTapped() {
        let isNewWorkout = state == .idle
        if isNewWorkout {
            workoutState = WorkoutState(configuration: timerConfiguration)
        }
        engine.start()
        if isNewWorkout && state == .countdown {
            onWorkoutStarted?(timerConfiguration)
        }
        saveState()
    }

    func pauseTapped() {
        engine.pause()
        saveState()
    }

    func resumeTapped() {
        engine.resume()
        saveState()
    }

    func resetTapped() {
        engine.reset()
        result = nil
        audioCoordinator.reset()
        clearSavedState()
        repCount = 0
        roundCount = 0
        currentSet = 1
        currentInterval = 1
        timeText = "00:00"
        currentRoundTimeText = "00:00"

        // Reset round tracking
        roundTracker.resetAll(numSets: timerConfiguration.numSets)
        lastRoundSplitTime = nil

        // Reset display throttling
        throttler.resetAll()
    }

    func finishTapped() {
        engine.finish()
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
        guard state == .running else { return }

        let currentTime = engine.getCurrentElapsed()
        let roundSplit = roundTracker.completeRound(currentElapsed: currentTime)

        // Sync published properties from tracker
        roundCount = roundTracker.roundCount
        lastRoundSplitTime = roundTracker.lastRoundSplitTime

        // Play haptic feedback via coordinator
        hapticCoordinator.handleEvent(.counterIncrement)

        // Announce round completion to VoiceOver
        let splitTimeFormatted = formatTimeForVoiceOver(roundSplit.splitTime)
        UIAccessibility.post(
            notification: .announcement,
            argument: "Round \(roundSplit.roundNumber) completed. Split time: \(splitTimeFormatted)"
        )

        // Save state after round completion
        saveState()
    }

    func undoLastRound() {
        guard roundTracker.undoLastRound() else { return }
        roundCount = roundTracker.roundCount
        lastRoundSplitTime = roundTracker.lastRoundSplitTime
        hapticCoordinator.handleEvent(.counterIncrement)
        saveState()
    }

    func skipCountdown() {
        engine.skipCountdown()
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
            .sink { _ in
                // Could check for state restoration here if needed
            }
            .store(in: &cancellables)
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
        workoutState.progress = WorkoutProgress(
            completedRoundSplits: roundTracker.allRoundSplits,
            currentSetRounds: roundTracker.currentSetRounds,
            setDurations: engine.setDurations,
            restElapsed: engine.restElapsedForRecovery
        )

        // Save to UserDefaults
        stateManager.saveState(workoutState)
    }

    private func clearSavedState() {
        stateManager.clearState()
    }

    // MARK: - Round Tracking Helpers
    private func finalizeWorkout(_ completion: TimerEngine.Completion, wasResting: Bool) {
        guard result == nil else { return }

        let wasCompleted = completion == .completed
        if wasCompleted, let finalSet = engine.setDurations.last {
            roundTracker.completeFinalRound(currentElapsed: finalSet.workingTime, currentSet: currentSet)
        } else if !wasResting {
            roundTracker.saveCurrentSetRounds(currentSet: currentSet)
        }

        let summary = WorkoutSummaryData(
            id: workoutState.id,
            configuration: configuration,
            duration: getTotalDuration(),
            repCount: repCount,
            roundCount: roundCount,
            wasCompleted: wasCompleted,
            roundSplits: allRounds.map { rounds in
                rounds.map { RoundSplitDisplay(roundNumber: $0.roundNumber, splitTime: $0.splitTime) }
            },
            setDurations: getSetDurations(),
            timestamp: workoutState.startTimestamp
        )
        let roundSplitsForPersistence: [[PersistenceController.RoundSplitInfo]] = roundTracker.allRoundSplits.map { setRounds in
            setRounds.map { roundData in
                PersistenceController.RoundSplitInfo(
                    roundNumber: roundData.roundNumber,
                    splitTime: roundData.splitTime,
                    cumulativeTime: roundData.cumulativeTime,
                    timestamp: roundData.timestamp
                )
            }
        }

        workoutState.elapsedSeconds = summary.duration
        persistence.saveWorkout(
            workoutState,
            wasCompleted: summary.wasCompleted,
            roundSplits: roundSplitsForPersistence
        )
        clearSavedState()
        result = summary
    }

    // MARK: - Timer Engine Delegate
    func timerDidTick(elapsed: TimeInterval, remaining: TimeInterval?) {
        let now = Date()

        if state == .countdown {
            if throttler.shouldUpdate(.time, now: now) {
                let seconds = Int(ceil(remaining ?? 0))
                countdownText = "\(max(1, seconds))"
            }
        } else if state == .resting {
            if throttler.shouldUpdate(.rest, now: now) {
                restTimeText = formatTime(remaining ?? 0)
                currentRoundTimeText = "00:00"
            }

            audioCoordinator.updateNowPlaying(
                timeText: "",
                isResting: true,
                restText: restTimeText
            )

        } else if state == .running {
            if timerConfiguration.timerType == .amrap {
                if throttler.shouldUpdate(.time, now: now) {
                    if let remaining = remaining {
                        timeText = formatTime(max(0, remaining))
                    } else {
                        timeText = formatTime(elapsed)
                    }
                }
                if throttler.shouldUpdate(.elapsed, now: now) {
                    elapsedTimeText = formatTime(elapsed)
                }
            } else {
                if throttler.shouldUpdate(.time, now: now) {
                    if timerConfiguration.timerType == .emom,
                       let intervalDuration = timerConfiguration.intervalDurationSeconds {
                        let intervalElapsed = elapsed.truncatingRemainder(dividingBy: Double(intervalDuration))
                        let intervalRemaining = Double(intervalDuration) - intervalElapsed
                        timeText = formatTime(max(0, intervalRemaining))
                    } else {
                        timeText = formatTime(elapsed)
                    }
                }

                // EMOM: update total elapsed display
                if timerConfiguration.timerType == .emom,
                   throttler.shouldUpdate(.elapsed, now: now) {
                    emomElapsedTimeText = formatTime(elapsed)
                }
            }

            if throttler.shouldUpdate(.round, now: now) {
                let currentRoundElapsed = roundTracker.getCurrentRoundElapsed(currentElapsed: elapsed)
                currentRoundTimeText = formatTime(currentRoundElapsed)
            }

            audioCoordinator.updateNowPlaying(
                timeText: timeText,
                isResting: false,
                restText: ""
            )

            workoutState.elapsedSeconds = elapsed
            workoutState.lastUpdateTimestamp = Date()
        }
    }

    func timerDidEmit(event: TimerEvent) {
        // Delegate side effects to coordinators
        hapticCoordinator.handleEvent(event)
        audioCoordinator.handleEvent(event)

        // VoiceOver announcements for key events
        announceEventForVoiceOver(event)

        // Update interval counter for EMOM
        if event == .intervalTick {
            currentInterval += 1
        }

        // Handle set completion
        if event == .setComplete {
            roundTracker.saveCurrentSetRounds(currentSet: currentSet)
        }
    }

    func timerDidChangeState(_ newState: TimerState) {
        let previousState = state
        let wasResting = previousState == .resting || workoutState.progress?.restElapsed != nil
        let movedToNextSet = currentSet != engine.currentSetNumber
        if previousState == .running && (newState == .resting || movedToNextSet) {
            roundTracker.saveCurrentSetRounds(currentSet: currentSet)
            roundTracker.resetForNewSet()
            roundCount = 0
            lastRoundSplitTime = nil
            if timerConfiguration.timerType == .forTime {
                repCount = 0
            }
            currentInterval = 1
        }

        self.state = newState
        workoutState.state = newState

        // Sync current set from engine
        currentSet = engine.currentSetNumber

        // Save state on state transitions
        if newState == .resting || newState == .running {
            saveState()
        }

        if newState == .finished, let completion = engine.completion {
            finalizeWorkout(completion, wasResting: wasResting)
        }
    }

    // MARK: - VoiceOver Announcements
    private func announceEventForVoiceOver(_ event: TimerEvent) {
        let message: String?
        switch event {
        case .start:
            message = "Workout started"
        case .finish:
            message = "Workout complete"
        case .intervalTick:
            message = "Interval \(currentInterval + 1)"
        case .lastMinute:
            message = "One minute remaining"
        case .thirtySecondsLeft:
            message = "Thirty seconds remaining"
        case .setComplete:
            message = "Set \(currentSet) complete"
        case .restStart:
            message = "Rest period"
        case .setStart:
            message = "Set \(currentSet) starting"
        default:
            message = nil
        }
        if let message = message {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    // MARK: - Helpers
    private func formatTime(_ seconds: TimeInterval) -> String {
        TimeFormatter.format(seconds)
    }

    private func formatTimeForVoiceOver(_ seconds: TimeInterval) -> String {
        TimeFormatter.formatForVoiceOver(seconds)
    }
}
