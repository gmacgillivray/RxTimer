import AVFoundation
import AudioToolbox

final class AudioService {
    static let shared = AudioService()

    private var players: [String: AVAudioPlayer] = [:]

    // System sound mapping for countdown (Option A: Classic Beep Progression)
    private let systemSoundMap: [String: SystemSoundID] = [
        "three": 1103,  // Low pitch beep (SMS Received 3)
        "two": 1104,    // Medium pitch beep (SMS Received 4)
        "one": 1105,    // Higher pitch beep (SMS Received 5)
        "go": 1057      // Sharp "tock" click
    ]

    private init() {
        preloadSounds()
    }

    private func preloadSounds() {
        // All sounds now use iOS system sounds - no audio files needed
    }

    func play(sound: String) {
        // Check if this is a system sound first
        if let systemSoundID = systemSoundMap[sound] {
            AudioServicesPlaySystemSound(systemSoundID)
        } else {
            // Fall back to loaded audio files
            players[sound]?.play()
        }
    }
}
