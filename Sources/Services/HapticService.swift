import Foundation
#if canImport(UIKit)
import UIKit
#endif

final class HapticService {
    static let shared = HapticService()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        // Pre-warm generators
        impactLight.prepare()
        impactRigid.prepare()
        notification.prepare()
    }

    func trigger(event: String) {
        switch event {
        case "start":
            impactRigid.impactOccurred()
            impactRigid.prepare()
        case "interval_tick":
            impactLight.impactOccurred()
            impactLight.prepare()
        case "last_minute", "30s_left":
            notification.notificationOccurred(.warning)
            notification.prepare()
        case "finish":
            notification.notificationOccurred(.success)
            notification.prepare()
        case "counter_increment":
            impactLight.impactOccurred()
            impactLight.prepare()
        default:
            break
        }
    }
}
