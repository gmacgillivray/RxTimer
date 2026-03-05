import Foundation

final class DisplayThrottler {
    enum DisplayCategory {
        case time
        case elapsed
        case rest
        case round
    }

    private var lastUpdateTimes: [DisplayCategory: Date] = [:]
    let updateInterval: TimeInterval

    init(updateInterval: TimeInterval = 1.0) {
        self.updateInterval = updateInterval
    }

    func shouldUpdate(_ category: DisplayCategory, now: Date = Date()) -> Bool {
        let lastUpdate = lastUpdateTimes[category] ?? .distantPast
        if now.timeIntervalSince(lastUpdate) >= updateInterval {
            lastUpdateTimes[category] = now
            return true
        }
        return false
    }

    func resetAll() {
        lastUpdateTimes.removeAll()
    }
}
