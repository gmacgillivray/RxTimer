import Foundation
import AVFoundation
import MediaPlayer

final class BackgroundAudioService {
    static let shared = BackgroundAudioService()

    private var audioPlayer: AVAudioPlayer?
    private let audioSession = AVAudioSession.sharedInstance()

    private init() {}

    func start() {
        do {
            // Configure audio session for background playback
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)

            // Create silent audio player (1 second of silence, looped)
            // In production, this should load from Resources/Audio/silence.m4a
            guard let url = Bundle.main.url(forResource: "silence", withExtension: "m4a") else {
                print("Warning: silence.m4a not found, background audio unavailable")
                return
            }

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = 0.05
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

        } catch {
            print("Failed to setup background audio: \(error)")
        }
    }

    func stop() {
        audioPlayer?.stop()
        try? audioSession.setActive(false)
    }

    func updateNowPlaying(timerType: String, elapsed: String, set: String?) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "\(timerType) Workout"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Elapsed: \(elapsed)"
        if let set = set {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = set
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
