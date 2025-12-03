import AVFoundation

final class AudioService {
    static let shared = AudioService()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        preloadSounds()
    }

    private func preloadSounds() {
        let sounds = ["start", "tick", "warn", "beep_1hz", "end", "three", "two", "one", "go"]
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
        players[sound]?.play()
    }
}
