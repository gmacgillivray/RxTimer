import AVFoundation
import AudioToolbox
import UIKit

final class AudioService: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioService()

    enum EMOMCue: String, CaseIterable {
        case go = "EMOMGo"
        case rest = "EMOMRest"
        case complete = "EMOMComplete"
    }

    private var cuePlayers: [EMOMCue: AVAudioPlayer] = [:]
    private var completionHandler: (() -> Void)?

    // System sound mapping for countdown (Option A: Classic Beep Progression)
    private let systemSoundMap: [String: SystemSoundID] = [
        "three": 1103,  // Low pitch beep (SMS Received 3)
        "two": 1104,    // Medium pitch beep (SMS Received 4)
        "one": 1105,    // Higher pitch beep (SMS Received 5)
        "go": 1057      // Sharp "tock" click
    ]

    private override init() {
        super.init()
        for cue in EMOMCue.allCases {
            guard let data = NSDataAsset(name: cue.rawValue)?.data,
                  let player = try? AVAudioPlayer(data: data) else { continue }
            player.delegate = self
            cuePlayers[cue] = player
        }
    }

    func play(sound: String) {
        if let systemSoundID = systemSoundMap[sound] {
            AudioServicesPlaySystemSound(systemSoundID)
        }
    }

    func play(_ cue: EMOMCue, onFinished: (() -> Void)? = nil) {
        if cue == .complete {
            completionHandler = onFinished
        }
        if let player = cuePlayers[cue] {
            player.currentTime = 0
            if player.play() { return }
        }
        if cue == .complete { finishCompletionCue() }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === cuePlayers[.complete] { finishCompletionCue() }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if player === cuePlayers[.complete] { finishCompletionCue() }
    }

    private func finishCompletionCue() {
        let handler = completionHandler
        completionHandler = nil
        handler?()
    }
}
