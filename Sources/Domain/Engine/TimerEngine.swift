import Foundation
import QuartzCore
import Combine

public protocol TimerEngineDelegate: AnyObject {
    func timerDidTick(elapsed: TimeInterval, remaining: TimeInterval?)
    func timerDidEmit(event: TimerEvent)
    func timerDidChangeState(_ state: TimerState)
}

// MARK: - Set Duration Tracking
/// Tracks actual duration of a completed set including working time and rest time
public struct SetDuration: Codable, Equatable {
    public let setNumber: Int
    public let workingTime: TimeInterval
    public let restTime: TimeInterval

    public var totalTime: TimeInterval {
        workingTime + restTime
    }

    public init(setNumber: Int, workingTime: TimeInterval, restTime: TimeInterval) {
        self.setNumber = setNumber
        self.workingTime = workingTime
        self.restTime = restTime
    }
}

public final class TimerEngine {
    enum Completion {
        case completed
        case endedEarly
    }
    // MARK: - Properties
    private var startWallTime: Date?
    private var pauseWallTime: Date?
    private var accumulated: TimeInterval = 0
    private var displayLink: CADisplayLink?
    private var configuration: TimerConfiguration
    private let now: () -> Date
    private var currentInterval: Int = 1

    // Multi-set support
    private var currentSet: Int = 1
    private var restStartTime: Date?
    private var restAccumulated: TimeInterval = 0
    private var isRestPaused = false
    private var completedSetDurations: [SetDuration] = []
    private var currentSetWorkingTime: TimeInterval = 0

    // Countdown support
    private var countdownRemaining: TimeInterval = 10.0
    private let countdownDuration: TimeInterval = 10.0

    // EMOM interval countdown tracking
    private var emomEmittedSeconds: Set<Int> = []

    // Rest period countdown tracking
    private var restEmittedSeconds: Set<Int> = []

    public private(set) var state: TimerState = .idle
    private(set) var completion: Completion?
    public weak var delegate: TimerEngineDelegate?

    // MARK: - Public Accessors
    public var currentSetNumber: Int { currentSet }
    public var setDurations: [SetDuration] { completedSetDurations }

    // MARK: - Initialization
    public convenience init(configuration: TimerConfiguration) {
        self.init(configuration: configuration, restoredState: nil)
    }

    init(configuration: TimerConfiguration, restoredState: WorkoutState?, now: @escaping () -> Date = Date.init) {
        self.configuration = configuration
        self.now = now
        guard let restoredState else { return }

        state = .paused
        accumulated = restoredState.elapsedSeconds
        currentSet = restoredState.currentSet
        currentInterval = restoredState.currentInterval ?? 1
        completedSetDurations = restoredState.progress?.setDurations ?? []
        if let restElapsed = restoredState.progress?.restElapsed {
            restAccumulated = restElapsed
            isRestPaused = true
            accumulated = 0
        }
    }

    var restElapsedForRecovery: TimeInterval? {
        guard state == .resting || isRestPaused else { return nil }
        return getRestElapsed()
    }

    // MARK: - Cleanup
    deinit {
        // Ensure CADisplayLink is properly invalidated to prevent retain cycles
        stopDisplayLink()
    }

    // MARK: - Public Methods
    public func start() {
        guard state == .idle || state == .paused || state == .resting else { return }

        if isRestPaused {
            isRestPaused = false
            restStartTime = now()
            changeState(.resting)
            startDisplayLink()
            delegate?.timerDidEmit(event: .resume)
            return
        }

        let wasResting = state == .resting

        if state == .idle {
            accumulated = 0
            currentInterval = 1
            currentSet = 1
            restAccumulated = 0
            completedSetDurations = []
            currentSetWorkingTime = 0
            countdownRemaining = countdownDuration

            // Start countdown instead of running
            startWallTime = now()
            changeState(.countdown)
            startDisplayLink()
            delegate?.timerDidEmit(event: .countdownStart)
            return
        }

        // If coming from rest, we're starting a new set
        if wasResting {
            // Record the rest time for the previous set
            let actualRestTime = restAccumulated
            if let restStart = restStartTime {
                let finalRestTime = actualRestTime + now().timeIntervalSince(restStart)
                recordRestTime(finalRestTime)
            }

            accumulated = 0
            currentInterval = 1
            currentSet += 1
            restAccumulated = 0
            emomEmittedSeconds.removeAll()
        }

        startWallTime = now()
        changeState(.running)
        startDisplayLink()

        // Emit appropriate start event
        delegate?.timerDidEmit(event: wasResting ? .setStart : .resume)
    }

    public func pause() {
        if state == .running {
            if let startTime = startWallTime {
                accumulated += now().timeIntervalSince(startTime)
            }
            pauseWallTime = now()
            changeState(.paused)
            stopDisplayLink()
            delegate?.timerDidEmit(event: .pause)
        } else if state == .countdown {
            // Pause logic for countdown
            if let startTime = startWallTime {
                let elapsed = now().timeIntervalSince(startTime)
                countdownRemaining = max(0, countdownDuration - elapsed)
            }
            changeState(.countdownPaused)
            stopDisplayLink()
        }
    }

    public func resume() {
        if state == .paused {
            start()
        } else if state == .countdownPaused {
            // Resume logic for countdown
            // Shift start time so that 'now - start' equals the elapsed time we had before pause
            let elapsedAlready = countdownDuration - countdownRemaining
            startWallTime = now().addingTimeInterval(-elapsedAlready)
            
            changeState(.countdown)
            startDisplayLink()
        }
    }

    public func reset() {
        stopDisplayLink()
        completion = nil
        changeState(.idle)
        startWallTime = nil
        pauseWallTime = nil
        restStartTime = nil
        accumulated = 0
        restAccumulated = 0
        isRestPaused = false
        currentInterval = 1
        currentSet = 1
        completedSetDurations = []
        currentSetWorkingTime = 0
        countdownRemaining = countdownDuration

        // Reset all countdown/warning tracking sets
        emomEmittedSeconds.removeAll()
        restEmittedSeconds.removeAll()
        amrapEmittedWarnings.removeAll()
    }

    public func finish() {
        guard state != .finished, state != .idle else { return }
        if let restElapsed = restElapsedForRecovery {
            recordRestTime(restElapsed)
            isRestPaused = false
        }

        // Accumulate any remaining time if we're currently running
        if state == .running, let startTime = startWallTime {
            accumulated += now().timeIntervalSince(startTime)
        }

        endWorkout(.endedEarly)
    }

    public func completeSet() {
        guard state == .running else { return }
        completeSet(workingTime: getCurrentElapsed(), isManual: true)
    }

    private func completeSet(workingTime: TimeInterval, isManual: Bool) {
        currentSetWorkingTime = workingTime
        accumulated = 0
        if isManual {
            delegate?.timerDidEmit(event: .setComplete)
        }

        if shouldStartNextSet() {
            startRest()
        } else {
            recordCompletedSet(workingTime: workingTime, restTime: 0)
            endWorkout(.completed)
        }
    }

    private func endWorkout(_ outcome: Completion) {
        completion = outcome
        stopDisplayLink()
        changeState(.finished)
        delegate?.timerDidEmit(event: .finish)
    }

    public func skipCountdown() {
        guard state == .countdown || state == .countdownPaused else { return }
        stopDisplayLink()
        startWallTime = now()
        accumulated = 0
        changeState(.running)
        delegate?.timerDidEmit(event: .start)
        startDisplayLink()
    }

    public func skipRest() {
        guard state == .resting else { return }
        stopDisplayLink()
        start()
    }

    public func getCurrentElapsed() -> TimeInterval {
        if completion == .completed {
            return completedSetDurations.last?.workingTime ?? 0
        }
        guard state == .running, let startTime = startWallTime else {
            return accumulated
        }
        return accumulated + now().timeIntervalSince(startTime)
    }

    public func getRestElapsed() -> TimeInterval {
        guard state == .resting, let restStart = restStartTime else {
            return restAccumulated
        }
        return restAccumulated + now().timeIntervalSince(restStart)
    }

    /// Returns the total duration of the workout including all working time and rest periods
    public func getTotalDuration() -> TimeInterval {
        // Sum all completed set durations
        let completedTotal = completedSetDurations.reduce(0.0) { $0 + $1.totalTime }

        // A completed final set is already included in completedTotal.
        let currentWorking = completion == .completed ? 0 : getCurrentElapsed()

        // Add current rest time if we're resting
        let currentRest = restElapsedForRecovery ?? 0

        return completedTotal + currentWorking + currentRest
    }

    // MARK: - Private Multi-Set Methods
    private func startRest() {
        guard let restDuration = configuration.restDurationSeconds, restDuration > 0 else {
            // No rest configured, record set with 0 rest and start next set immediately
            recordCompletedSet(workingTime: currentSetWorkingTime, restTime: 0)
            accumulated = 0
            currentInterval = 1
            currentSet += 1
            restAccumulated = 0
            emomEmittedSeconds.removeAll()
            startWallTime = now()
            changeState(.running)
            delegate?.timerDidEmit(event: .setStart)
            startDisplayLink()
            return
        }

        // Record the working time for this set (rest time will be recorded when rest ends)
        recordCompletedSet(workingTime: currentSetWorkingTime, restTime: 0)

        stopDisplayLink()
        accumulated = 0
        restStartTime = now()
        restAccumulated = 0

        // Reset rest countdown tracking for this rest period
        restEmittedSeconds.removeAll()

        changeState(.resting)
        delegate?.timerDidEmit(event: .restStart)
        startDisplayLink()
    }

    private func shouldStartNextSet() -> Bool {
        return currentSet < configuration.numSets
    }

    /// Records the rest time for the most recently completed set
    private func recordRestTime(_ restTime: TimeInterval) {
        // Update the last recorded set with actual rest time
        if !completedSetDurations.isEmpty {
            let lastIndex = completedSetDurations.count - 1
            let lastSet = completedSetDurations[lastIndex]
            completedSetDurations[lastIndex] = SetDuration(
                setNumber: lastSet.setNumber,
                workingTime: lastSet.workingTime,
                restTime: restTime
            )
        }
    }

    /// Records a completed set with working and rest time
    private func recordCompletedSet(workingTime: TimeInterval, restTime: TimeInterval) {
        let duration = SetDuration(
            setNumber: currentSet,
            workingTime: workingTime,
            restTime: restTime
        )
        completedSetDurations.append(duration)
    }

    // MARK: - Private Methods
    private func changeState(_ newState: TimerState) {
        state = newState
        delegate?.timerDidChangeState(newState)
    }

    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc func tick() {
        if state == .countdown {
            handleCountdownTick()
        } else if state == .resting {
            handleRestTick()
        } else if state == .running {
            handleRunningTick()
        }
    }

    private func handleCountdownTick() {
        guard let startTime = startWallTime else { return }

        let elapsed = now().timeIntervalSince(startTime)
        let remaining = max(0, countdownDuration - elapsed)

        // Emit beep events only at 3, 2, and 1
        // Use ceil() to align beeps with display (beep when crossing 3.0, 2.0, 1.0)
        let currentSecond = Int(ceil(remaining))
        let previousSecond = Int(ceil(countdownRemaining))
        if currentSecond != previousSecond {
            if currentSecond == 3 || currentSecond == 2 || currentSecond == 1 {
                delegate?.timerDidEmit(event: .countdown(currentSecond))
            }
        }

        countdownRemaining = remaining
        delegate?.timerDidTick(elapsed: elapsed, remaining: remaining)

        // When countdown finishes, transition to running
        if remaining <= 0 {
            startWallTime = now()  // Reset start time for actual workout
            accumulated = 0
            changeState(.running)
            delegate?.timerDidEmit(event: .start)
        }
    }

    private func handleRunningTick() {
        guard let startTime = startWallTime else { return }

        let elapsed = accumulated + now().timeIntervalSince(startTime)
        let remaining = calculateRemaining(elapsed: elapsed)

        // Check for set completion
        if let limit = configuration.totalDurationSeconds, elapsed >= Double(limit) {
            completeSet(workingTime: Double(limit), isManual: false)
            return
        }

        // Check for interval transitions (EMOM)
        if configuration.timerType == .emom {
            checkIntervalTransition(elapsed: elapsed)
        }

        // Emit timing warnings for AMRAP
        if configuration.timerType == .amrap {
            checkAMRAPWarnings(remaining: remaining)
        }

        delegate?.timerDidTick(elapsed: elapsed, remaining: remaining)
    }

    private func handleRestTick() {
        guard let restStart = restStartTime,
              let restDuration = configuration.restDurationSeconds else { return }

        let restElapsed = restAccumulated + now().timeIntervalSince(restStart)
        let restRemaining = Double(restDuration) - restElapsed

        // Emit countdown sounds at 3, 2, 1 seconds before rest ends
        // Use ceil() to align beeps with display
        let currentSecond = Int(ceil(restRemaining))

        if (1...3).contains(currentSecond), restEmittedSeconds.insert(currentSecond).inserted {
            delegate?.timerDidEmit(event: .countdown(currentSecond))
        }

        // Check if rest period is complete
        if restRemaining <= 0 {
            start() // Automatically start next set
            return
        }

        // Notify delegate with rest countdown
        delegate?.timerDidTick(elapsed: restElapsed, remaining: restRemaining)
    }

    private func calculateRemaining(elapsed: TimeInterval) -> TimeInterval? {
        guard let total = configuration.totalDurationSeconds else { return nil }
        return Double(total) - elapsed
    }

    private func checkIntervalTransition(elapsed: TimeInterval) {
        guard let intervalDuration = configuration.intervalDurationSeconds,
              let numIntervals = configuration.numIntervals else { return }

        // Calculate time until next interval
        let timeInCurrentInterval = elapsed.truncatingRemainder(dividingBy: Double(intervalDuration))
        let timeUntilNextInterval = Double(intervalDuration) - timeInCurrentInterval

        // Emit countdown sounds at 3, 2, 1 seconds before interval transition
        // Use ceil() to align beeps with display
        let currentSecond = Int(ceil(timeUntilNextInterval))

        if (1...3).contains(currentSecond), currentInterval < numIntervals,
           emomEmittedSeconds.insert(currentSecond).inserted {
            delegate?.timerDidEmit(event: .countdown(currentSecond))
        }

        // Check for interval transition
        let newInterval = Int(elapsed / Double(intervalDuration)) + 1
        if newInterval != currentInterval && newInterval <= numIntervals {
            currentInterval = newInterval
            delegate?.timerDidEmit(event: .intervalTick)

            // Reset countdown tracking for next interval
            emomEmittedSeconds.removeAll()
        }
    }

    private var amrapEmittedWarnings: Set<String> = []

    private func checkAMRAPWarnings(remaining: TimeInterval?) {
        guard let remaining = remaining else { return }

        if remaining <= 60 && remaining > 59, amrapEmittedWarnings.insert("lastMinute").inserted {
            delegate?.timerDidEmit(event: .lastMinute)
        }

        if remaining <= 30 && remaining > 29, amrapEmittedWarnings.insert("thirtySeconds").inserted {
            delegate?.timerDidEmit(event: .thirtySecondsLeft)
        }

        if remaining <= 10 && remaining > 0, amrapEmittedWarnings.insert("tenSecCountdown").inserted {
            delegate?.timerDidEmit(event: .countdownTick(10))
        }
    }
}


