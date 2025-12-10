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
        // Only preload non-system sounds
        let sounds = ["start", "tick", "warn", "beep_1hz", "end"]
        for sound in sounds {
            guard let url = Bundle.main.url(forResource: sound, withExtension: "caf") else {
                print("Warning: \(sound).caf not found")
                continue
            }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[sound] = player
            }
        }
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
