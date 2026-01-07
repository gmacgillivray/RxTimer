import Foundation

public enum TimerEvent: Equatable {
    case start
    case finish
    case pause
    case resume
    case tick(TimeInterval)
    case countdown(Int) // 3, 2, 1
    case countdownTick(TimeInterval) // 10s warning
    case intervalTick
    case setComplete
    case setStart
    case restStart
    case countdownStart
    case lastMinute
    case thirtySecondsLeft
    case counterIncrement
}
