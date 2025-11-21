import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission not granted")
            }
        }
    }

    private func ensureAuthorized(_ completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                completion(true)
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            default:
                completion(false)
            }
        }
    }

    // MARK: - Public API
    func scheduleWorkoutNotifications(configuration: TimerConfiguration, startTime: Date) {
        ensureAuthorized { authorized in
            guard authorized else {
                print("Notifications not authorized. Skipping scheduling.")
                return
            }
            // Proceed with validated scheduling on main queue
            DispatchQueue.main.async {
                self.performScheduling(configuration: configuration, startTime: startTime)
            }
        }
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Internal Scheduling
    private func performScheduling(configuration: TimerConfiguration, startTime: Date) {
        // Validate total duration if available
        if let total = configuration.totalDurationSeconds, total < 1 {
            print("Schedule: Invalid totalDuration \(total). Aborting scheduling.")
            return
        }

        // Use a scoped session identifier to avoid nuking unrelated notifications
        let sessionID = UUID().uuidString

        // Schedule based on timer type
        switch configuration.timerType {
        case .amrap:
            guard let total = configuration.totalDurationSeconds, total >= 1 else {
                print("AMRAP: Missing or invalid total duration.")
                return
            }
            let ids = NotificationIDs(
                lastMinute: "last_minute_\(sessionID)",
                thirtySeconds: "30s_warning_\(sessionID)",
                completion: "workout_complete_\(sessionID)"
            )
            // Cancel only our identifiers for this session (noop if none exist)
            center.removePendingNotificationRequests(withIdentifiers: ids.all())
            scheduleAMRAPNotifications(startTime: startTime, duration: total, ids: ids)

        case .emom:
            let intervals = configuration.numIntervals ?? 0
            let intervalDuration = configuration.intervalDurationSeconds ?? 60
            guard intervals > 0, intervalDuration >= 1 else {
                print("EMOM: Invalid intervals=\(intervals) or intervalDuration=\(intervalDuration)")
                return
            }
            // Build identifiers for each interval to allow scoped cancellation
            let ids = (1...intervals).map { "interval_\($0)_\(sessionID)" }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            scheduleEMOMNotifications(startTime: startTime, intervals: intervals, intervalDuration: intervalDuration, identifiers: ids)

        case .forTime:
            if let timeCap = configuration.timeCapSeconds {
                guard timeCap >= 1 else {
                    print("ForTime: Invalid timeCap=\(timeCap)")
                    return
                }
                let id = "time_cap_\(sessionID)"
                center.removePendingNotificationRequests(withIdentifiers: [id])
                scheduleForTimeNotification(startTime: startTime, timeCap: timeCap, identifier: id)
            } else {
                print("ForTime: Missing timeCapSeconds.")
            }
        }
    }

    // MARK: - Helpers
    private struct NotificationIDs {
        let lastMinute: String
        let thirtySeconds: String
        let completion: String
        func all() -> [String] { [lastMinute, thirtySeconds, completion] }
    }

    private func scheduleAMRAPNotifications(startTime: Date, duration: Int, ids: NotificationIDs) {
        guard duration >= 1 else {
            print("AMRAP: Invalid duration \(duration). Skipping notifications.")
            return
        }

        let now = Date()
        let baseOffset = max(0, startTime.timeIntervalSince(now))

        // Last minute warning
        if duration >= 60 {
            let t = duration - 60
            if t >= 1 {
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: baseOffset + Double(t),
                    repeats: false
                )
                let content = UNMutableNotificationContent()
                content.title = "1 Minute Remaining"
                content.body = "Push to the finish!"
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: ids.lastMinute,
                    content: content,
                    trigger: trigger
                )
                center.add(request) { error in
                    if let error = error { print("Failed to schedule \(request.identifier): \(error)") }
                }
            }
        }

        // 30 second warning
        if duration >= 30 {
            let t = duration - 30
            if t >= 1 {
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: baseOffset + Double(t),
                    repeats: false
                )
                let content = UNMutableNotificationContent()
                content.title = "30 Seconds Left"
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: ids.thirtySeconds,
                    content: content,
                    trigger: trigger
                )
                center.add(request) { error in
                    if let error = error { print("Failed to schedule \(request.identifier): \(error)") }
                }
            }
        }

        // Completion
        let completionTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: baseOffset + Double(duration),
            repeats: false
        )
        let completionContent = UNMutableNotificationContent()
        completionContent.title = "Workout Complete!"
        completionContent.sound = .default

        let completionRequest = UNNotificationRequest(
            identifier: ids.completion,
            content: completionContent,
            trigger: completionTrigger
        )
        center.add(completionRequest) { error in
            if let error = error { print("Failed to schedule \(completionRequest.identifier): \(error)") }
        }
    }

    private func scheduleEMOMNotifications(startTime: Date, intervals: Int, intervalDuration: Int, identifiers: [String]) {
        let now = Date()
        let baseOffset = max(0, startTime.timeIntervalSince(now))

        for i in 1...intervals {
            let seconds = i * intervalDuration
            guard seconds >= 1 else { continue }

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: baseOffset + Double(seconds),
                repeats: false
            )
            let content = UNMutableNotificationContent()
            content.title = "EMOM Interval \(i + 1)"
            content.body = "Starting interval \(i + 1) of \(intervals)"
            content.sound = .default

            let id = identifiers[i - 1]
            let request = UNNotificationRequest(
                identifier: id,
                content: content,
                trigger: trigger
            )
            center.add(request) { error in
                if let error = error { print("Failed to schedule \(request.identifier): \(error)") }
            }
        }
    }

    private func scheduleForTimeNotification(startTime: Date, timeCap: Int, identifier: String) {
        guard timeCap >= 1 else { return }

        let now = Date()
        let baseOffset = max(0, startTime.timeIntervalSince(now))

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: baseOffset + Double(timeCap),
            repeats: false
        )
        let content = UNMutableNotificationContent()
        content.title = "Time Cap Reached"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            if let error = error { print("Failed to schedule \(request.identifier): \(error)") }
        }
    }
}
