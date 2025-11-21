import Foundation
import Combine
import SwiftUI

/// ViewModel for MainContainerView - manages navigation and Quick Start feature
class MainContainerViewModel: ObservableObject, ConfigurationProvider {
    // MARK: - Published Properties

    /// Current navigation state
    @Published var navigationState: AppNavigationState = .home

    /// Whether Quick Start countdown is active
    @Published var isCountingDown = false

    /// Current countdown seconds remaining
    @Published var countdownSeconds = 10

    // MARK: - Private Properties

    /// Combine timer for countdown
    private var countdownTimer: AnyCancellable?

    /// Configuration pending Quick Start completion
    private var pendingConfig: TimerConfiguration?

    // MARK: - Quick Start

    /// Initiates Quick Start countdown for specified timer type
    /// - Parameter timerType: The type of timer to Quick Start
    func initiateQuickStart(for timerType: TimerType) {
        // Get smart default configuration
        let config = quickStartConfiguration(for: timerType)

        // Store pending config
        pendingConfig = config

        // Reset countdown
        countdownSeconds = 10
        isCountingDown = true

        // Start countdown timer
        countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleCountdownTick()
            }
    }

    /// Cancels the Quick Start countdown
    func cancelQuickStart() {
        countdownTimer?.cancel()
        countdownTimer = nil
        isCountingDown = false
        countdownSeconds = 10
        pendingConfig = nil
    }

    /// Handles each countdown tick
    private func handleCountdownTick() {
        countdownSeconds -= 1

        if countdownSeconds <= 0 {
            completeQuickStart()
        }
    }

    /// Completes Quick Start and navigates to active workout
    private func completeQuickStart() {
        countdownTimer?.cancel()
        countdownTimer = nil
        isCountingDown = false

        if let config = pendingConfig {
            // Navigate directly to active workout (skip configuration screen)
            navigationState = .activeWorkout(config, restoredState: nil)
        }

        pendingConfig = nil
    }

    // MARK: - Accessibility

    /// Returns VoiceOver label for Quick Start button
    /// - Parameter timerType: The timer type
    /// - Returns: Accessibility label string
    func quickStartAccessibilityLabel(for timerType: TimerType) -> String {
        let config = quickStartConfiguration(for: timerType)
        return config.quickStartAccessibilityDescription()
    }
}
