import Foundation

enum TimeFormatter {
    static func format(_ seconds: TimeInterval) -> String {
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

    static func formatForVoiceOver(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        var components: [String] = []

        if hours > 0 {
            components.append("\(hours) hour\(hours == 1 ? "" : "s")")
        }
        if minutes > 0 {
            components.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
        }
        if secs > 0 || components.isEmpty {
            components.append("\(secs) second\(secs == 1 ? "" : "s")")
        }

        return components.joined(separator: " ")
    }

    static func formatDelta(_ seconds: TimeInterval) -> String {
        let absSeconds = abs(seconds)
        let totalSeconds = Int(absSeconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60

        let timeString: String
        if minutes > 0 {
            timeString = String(format: "%d:%02d", minutes, secs)
        } else {
            timeString = String(format: "0:%02d", secs)
        }

        if seconds == 0 {
            return "\(timeString) even"
        }
        return seconds > 0 ? "+\(timeString) slower" : "-\(timeString) faster"
    }

    static func formatDeltaForVoiceOver(_ seconds: TimeInterval) -> String {
        let absSeconds = abs(seconds)
        let totalSeconds = Int(absSeconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60

        var components: [String] = []
        if minutes > 0 {
            components.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
        }
        if secs > 0 || components.isEmpty {
            components.append("\(secs) second\(secs == 1 ? "" : "s")")
        }

        let timeString = components.joined(separator: " ")
        if seconds == 0 {
            return "\(timeString) even"
        }
        return seconds > 0 ? "\(timeString) slower" : "\(timeString) faster"
    }
}
