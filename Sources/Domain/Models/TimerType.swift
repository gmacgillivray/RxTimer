import Foundation

public enum TimerType: String, Codable, CaseIterable {
    case forTime = "FT"
    case amrap = "AMRAP"
    case emom = "EMOM"

    var displayName: String {
        switch self {
        case .forTime: return "For Time"
        case .amrap: return "AMRAP"
        case .emom: return "EMOM"
        }
    }

    var countsUp: Bool {
        switch self {
        case .forTime, .emom: return true
        case .amrap: return false
        }
    }
}
