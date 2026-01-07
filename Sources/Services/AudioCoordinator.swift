import Foundation
import Combine

class AudioCoordinator {
    private let audio = AudioService.shared
    private let backgroundAudio = BackgroundAudioService.shared
    
    // Store configuration to handle Now Playing updates
    private var timerType: TimerType?
    private var numSets: Int = 0
    private var currentSet: Int = 1
    
    func configure(timerType: TimerType, numSets: Int) {
        self.timerType = timerType
        self.numSets = numSets
        self.currentSet = 1
    }

    func reset() {
        backgroundAudio.stop()
        backgroundAudio.clearNowPlaying()
        self.currentSet = 1
    }
    
    func handleEvent(_ event: TimerEvent) {
        playAudioForEvent(event)
        
        switch event {
        case .start:
            backgroundAudio.start()
        case .pause, .finish:
            backgroundAudio.stop()
            if event == .finish {
                backgroundAudio.clearNowPlaying()
            }
        case .resume:
            backgroundAudio.start()
        case .restStart:
            // Update Now Playing for rest
            backgroundAudio.updateNowPlaying(
                timerType: "Rest",
                elapsed: "00:00", // Will be updated by ticks
                set: "Between Sets"
            )
        case .setStart:
             // Update Now Playing for work
             if let type = timerType {
                 let setInfo = numSets > 1 ? "Set \(currentSet) of \(numSets)" : nil
                 backgroundAudio.updateNowPlaying(
                     timerType: type.displayName,
                     elapsed: "00:00",
                     set: setInfo
                 )
             }
        case .setComplete:
            currentSet += 1
        default:
            break
        }
    }
    
    // Called by ViewModel on every tick to update Now Playing center
    func updateNowPlaying(timeText: String, isResting: Bool, restText: String) {
        if isResting {
            backgroundAudio.updateNowPlaying(
                timerType: "Rest",
                elapsed: restText,
                set: "Between Sets"
            )
        } else if let type = timerType {
            let setInfo = numSets > 1 ? "Set \(currentSet) of \(numSets)" : nil
            backgroundAudio.updateNowPlaying(
                timerType: type.displayName,
                elapsed: timeText,
                set: setInfo
            )
        }
    }
    
    private func playAudioForEvent(_ event: TimerEvent) {
        switch event {
        case .countdown(let seconds):
            switch seconds {
            case 3: audio.play(sound: "three")
            case 2: audio.play(sound: "two")
            case 1: audio.play(sound: "one")
            default: break
            }
        case .start:
            audio.play(sound: "go")
        default:
            break
        }
    }
}
