import SwiftUI
import UIKit

struct TimerView: View {
    @StateObject private var viewModel: TimerViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let onWorkoutStateChange: ((Bool) -> Void)?
    let onFinish: ((WorkoutSummaryData) -> Void)?

    init(
        configuration: TimerConfiguration,
        restoredState: WorkoutState? = nil,
        onWorkoutStateChange: ((Bool) -> Void)? = nil,
        onFinish: ((WorkoutSummaryData) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: TimerViewModel(configuration: configuration, restoredState: restoredState))
        self.onWorkoutStateChange = onWorkoutStateChange
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            // PERFORMANCE: Cache gradient backgrounds using .drawingGroup()
            // This flattens the two full-screen gradients into a single layer,
            // reducing GPU overhead from 60fps re-rendering
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color("SecondaryBackground"), Color.black, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Accent glow effect based on timer type
                RadialGradient(
                    colors: [accentColorForTimerType.opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 50,
                    endRadius: 400
                )
                .ignoresSafeArea()
            }
            .drawingGroup() // Flatten gradient layers to optimize rendering

            // Show rest screen, countdown, or main timer
            if viewModel.state == .resting {
                restPeriodView
            } else if viewModel.state == .countdown {
                countdownView
            } else {
                mainTimerView
            }
        }
        .navigationTitle(viewModel.timerTypeDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.state != .idle)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.finishTapped()
                    // Create summary data and call finish callback
                    let summaryData = createSummaryData(wasCompleted: false)
                    onFinish?(summaryData)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Done")
                    }
                    .foregroundColor(.secondary)
                }
                .disabled(viewModel.state == .idle)
                .opacity(viewModel.state == .idle ? 0 : 1)
                .accessibilityHidden(viewModel.state == .idle)
            }
        }
        .onAppear {
            NotificationService.shared.requestAuthorization()
        }
        .onChange(of: viewModel.state) { newState in
            let isActive = newState != .idle && newState != .finished
            onWorkoutStateChange?(isActive)

            // When workout finishes, create summary data and call callback
            if newState == .finished {
                let summaryData = createSummaryData(wasCompleted: true)
                onFinish?(summaryData)
            }
        }
    }

    // Create summary data from current workout state
    private func createSummaryData(wasCompleted: Bool) -> WorkoutSummaryData {
        return WorkoutSummaryData(
            configuration: viewModel.configuration,
            duration: viewModel.getTotalDuration(),
            repCount: viewModel.repCount,
            roundCount: viewModel.roundCount,
            wasCompleted: wasCompleted,
            roundSplits: convertRoundSplitsForDisplay(),
            setDurations: viewModel.getSetDurations()
        )
    }

    // MARK: - Countdown View
    private var countdownView: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("Get Ready")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .textCase(.uppercase)

            Text(viewModel.countdownText)
                .font(.system(size: horizontalSizeClass == .regular ? 240 : 120, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColorForTimerType, accentColorForTimerType.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: accentColorForTimerType.opacity(0.5), radius: 30, x: 0, y: 0)
                .accessibilityLabel("Starting in \(viewModel.countdownText) seconds")

            Spacer()
        }
        .padding()
    }

    // MARK: - Rest Period View
    private var restPeriodView: some View {
        VStack(spacing: 40) {
            Spacer()

            // Rest heading
            VStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("REST")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .textCase(.uppercase)

                Text("Between Sets")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Rest countdown
            Text(viewModel.restTimeText)
                .font(.system(size: restTimerFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .blue.opacity(0.5), radius: 30, x: 0, y: 0)
                .accessibilityLabel("Rest Time Remaining: \(viewModel.restTimeText)")

            // Set indicator
            if viewModel.numSets > 1 {
                VStack(spacing: 8) {
                    Text("Completed Set \(viewModel.currentSet - 1)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Next: Set \(viewModel.currentSet) of \(viewModel.numSets)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            // Skip rest button
            Button(action: {
                viewModel.skipRest()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Skip Rest")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                )
                .foregroundColor(.white)
            }
            .padding(.horizontal)
            .accessibilityLabel("Skip Rest and Start Next Set")

            Spacer()
                .frame(height: 50)
        }
        .padding()
    }

    // MARK: - Main Timer View
    private var mainTimerView: some View {
        VStack(spacing: 20) {
                Spacer()

                // Time display with gradient
                VStack(spacing: 12) {
                    Text(viewModel.timeText)
                        .font(.system(size: mainTimerFontSize, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: accentColorForTimerType.opacity(0.3), radius: 20, x: 0, y: 0)
                        .opacity(viewModel.state == .idle ? 0.6 : 1.0)
                        .saturation(viewModel.state == .idle ? 0.7 : 1.0)
                        .accessibilityLabel(viewModel.timerType == .amrap ? "Time Remaining: \(viewModel.timeText)" : "Elapsed Time: \(viewModel.timeText)")

                    // State indicator (always shown)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(stateIndicatorColor)
                            .frame(width: 8, height: 8)
                        Text(stateLabel)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                }

                // Elapsed time display (AMRAP only)
                if viewModel.timerType == .amrap && viewModel.state == .running {
                    VStack(spacing: 6) {
                        Text("Elapsed Time")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(viewModel.elapsedTimeText)
                            .font(.system(size: elapsedTimeFontSize, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white.opacity(0.7))
                            .accessibilityLabel("Elapsed Time: \(viewModel.elapsedTimeText)")
                    }
                }

                // Current round time display
                if viewModel.state == .running {
                    VStack(spacing: 6) {
                        Text("Current Round")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(viewModel.currentRoundTimeText)
                            .font(.system(size: currentRoundFontSize, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(accentColorForTimerType)
                    }
                }

                // Last round time display (only show after completing at least one round)
                if let lastSplit = viewModel.lastRoundSplitTime,
                   viewModel.roundCount > 0,
                   viewModel.state == .running {
                    VStack(spacing: 6) {
                        Text("Last Round")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(formatTime(lastSplit))
                            .font(.system(size: lastRoundFontSize, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white.opacity(0.5))

                        // Optional delta indicator
                        if let delta = viewModel.currentRoundVsLastDelta {
                            Text(formatDelta(delta))
                                .font(.system(size: deltaFontSize, weight: .medium))
                                .foregroundColor(delta > 0 ? .orange : .green)
                        }
                    }
                    .padding(.top, -8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Last Round: \(formatTime(lastSplit))\(viewModel.currentRoundVsLastDelta.map { ", \(formatDeltaForVoiceOver($0))" } ?? "")")
                }

                // Round counter button
                if viewModel.showCounterButton && viewModel.state == .running {
                    Button(action: {
                        viewModel.completeRound()
                    }) {
                        VStack(spacing: 8) {
                            Text("Round \(viewModel.roundCount + 1)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Tap to Complete Round")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .padding(.horizontal, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("CardBackground"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [accentColorForTimerType.opacity(0.6), accentColorForTimerType.opacity(0.2)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: accentColorForTimerType.opacity(0.3), radius: 15, x: 0, y: 5)
                        )
                    }
                    .accessibilityLabel("Tap to complete round \(viewModel.roundCount + 1)")
                }

                // Secondary info (set/interval indicators)
                VStack(spacing: 8) {
                    if viewModel.numSets > 1 {
                        VStack(spacing: 4) {
                            // Visual progress dots
                            HStack(spacing: 6) {
                                ForEach(1...viewModel.numSets, id: \.self) { setNumber in
                                    Circle()
                                        .fill(setNumber <= viewModel.currentSet ? Color.white : Color.white.opacity(0.2))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .accessibilityHidden(true) // Text indicator provides the info

                            // Text indicator
                            InfoPill(
                                icon: "square.stack.3d.up.fill",
                                text: "Set \(viewModel.currentSet) of \(viewModel.numSets)"
                            )
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Set \(viewModel.currentSet) of \(viewModel.numSets)")
                    }

                    if viewModel.timerType == .emom {
                        InfoPill(
                            icon: "clock.fill",
                            text: "Interval \(viewModel.currentInterval) of \(viewModel.numIntervals)"
                        )
                    }
                }

                Spacer()

                // Control buttons
                controlButtons

                Spacer()
                    .frame(height: 50)
            }
            .padding()
    }

    private var accentColorForTimerType: Color {
        switch viewModel.timerType {
        case .forTime:
            return .accentColor
        case .amrap:
            return .orange
        case .emom:
            return .blue
        }
    }

    private var mainTimerFontSize: CGFloat {
        // iPad: 192 (double), iPhone: 96
        horizontalSizeClass == .regular ? 192 : 96
    }

    private var restTimerFontSize: CGFloat {
        // iPad: 240 (double), iPhone: 120
        horizontalSizeClass == .regular ? 240 : 120
    }

    private var elapsedTimeFontSize: CGFloat {
        // iPad: 57 (30% of 192), iPhone: 28 (30% of 96)
        horizontalSizeClass == .regular ? 57 : 28
    }

    private var currentRoundFontSize: CGFloat {
        // iPad: 76 (40% of 192), iPhone: 38 (40% of 96)
        horizontalSizeClass == .regular ? 76 : 38
    }

    private var lastRoundFontSize: CGFloat {
        // iPad: 53 (28% of 192), iPhone: 28 (29% of 96)
        horizontalSizeClass == .regular ? 53 : 28
    }

    private var deltaFontSize: CGFloat {
        // iPad: 16, iPhone: 12
        horizontalSizeClass == .regular ? 16 : 12
    }

    // MARK: - Button Sizing (Device Adaptive)

    private var primaryButtonFontSize: CGFloat {
        horizontalSizeClass == .regular ? 22 : 18
    }

    private var secondaryButtonFontSize: CGFloat {
        horizontalSizeClass == .regular ? 20 : 16
    }

    private var primaryIconSize: CGFloat {
        horizontalSizeClass == .regular ? 24 : 20
    }

    private var secondaryIconSize: CGFloat {
        horizontalSizeClass == .regular ? 20 : 16
    }

    private var buttonContainerMaxWidth: CGFloat? {
        // On iPad and landscape, constrain button width to prevent excessive stretching
        // In portrait iPhone, allow full width
        horizontalSizeClass == .regular ? 700 : nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
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

    private func formatDelta(_ seconds: TimeInterval) -> String {
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

        return seconds > 0 ? "+\(timeString) slower" : "-\(timeString) faster"
    }

    private func formatDeltaForVoiceOver(_ seconds: TimeInterval) -> String {
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
        return seconds > 0 ? "\(timeString) slower" : "\(timeString) faster"
    }

    private func convertRoundSplitsForDisplay() -> [[RoundSplitDisplay]] {
        return viewModel.allRounds.map { setRounds in
            setRounds.map { roundData in
                RoundSplitDisplay(
                    roundNumber: roundData.roundNumber,
                    splitTime: roundData.splitTime
                )
            }
        }
    }

    private var stateIndicatorColor: Color {
        switch viewModel.state {
        case .idle:
            return .gray
        case .countdown:
            return .orange
        case .running:
            return .green
        case .paused:
            return .yellow
        case .resting:
            return .blue
        case .finished:
            return .accentColor
        }
    }

    private var stateLabel: String {
        switch viewModel.state {
        case .idle:
            return "Ready"
        case .countdown:
            return "Starting"
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .resting:
            return "Resting"
        case .finished:
            return "Finished"
        }
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 12) {
            // Primary action button (Start/Pause/Resume)
            Button(action: {
                if viewModel.state == .idle {
                    viewModel.startTapped()
                } else if viewModel.state == .running {
                    viewModel.pauseTapped()
                } else if viewModel.state == .paused {
                    viewModel.resumeTapped()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: buttonIcon)
                        .font(.system(size: primaryIconSize, weight: .semibold))
                    Text(buttonLabel)
                        .font(.system(size: primaryButtonFontSize, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: buttonGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: accentColorForTimerType.opacity(0.4), radius: 12, x: 0, y: 6)
                )
                .foregroundColor(.white)
            }
            .accessibilityLabel(buttonAccessibilityLabel)
            .disabled(viewModel.state == .finished)

            // Complete Set / Finish Workout / Skip Rest button (adaptive)
            Button(action: {
                if viewModel.state == .resting {
                    // Skip rest and start next set
                    viewModel.skipRest()
                } else if viewModel.state == .running {
                    // Complete set or finish workout
                    if viewModel.currentSet < viewModel.numSets {
                        // Not final set - complete set and start rest
                        viewModel.completeSetTapped()
                    } else {
                        // Final set - finish entire workout
                        viewModel.completeSetTapped() // This will call finish internally
                        // Create summary data and call finish callback
                        let summaryData = createSummaryData(wasCompleted: false)
                        onFinish?(summaryData)
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: finishButtonIcon)
                        .font(.system(size: secondaryIconSize, weight: .semibold))
                    Text(finishButtonLabel)
                        .font(.system(size: secondaryButtonFontSize, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(finishButtonBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(finishButtonStroke, lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
            }
            .accessibilityLabel(finishButtonAccessibilityLabel)
            .disabled(viewModel.state == .idle || viewModel.state == .paused || viewModel.state == .finished)
            .opacity((viewModel.state == .idle || viewModel.state == .paused || viewModel.state == .finished) ? 0.4 : 1)
        }
        .frame(maxWidth: buttonContainerMaxWidth)
        .padding(.horizontal)
    }

    private var buttonIcon: String {
        switch viewModel.state {
        case .idle: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        default: return "play.fill"
        }
    }

    private var buttonGradientColors: [Color] {
        switch viewModel.state {
        case .idle, .paused:
            return [accentColorForTimerType, accentColorForTimerType.opacity(0.7)]
        case .running:
            return [.orange, .orange.opacity(0.7)]
        default:
            return [.gray, .gray.opacity(0.7)]
        }
    }


    // MARK: - Computed Properties
    private var buttonLabel: String {
        switch viewModel.state {
        case .idle: return "Start"
        case .countdown: return "Starting"
        case .running: return "Pause"
        case .paused: return "Resume"
        case .resting: return "Resting"
        case .finished: return "Finished"
        }
    }

    private var finishButtonLabel: String {
        if viewModel.state == .resting {
            return "Skip Rest"
        } else if viewModel.state == .running {
            if viewModel.currentSet < viewModel.numSets {
                return "Complete Set"
            } else {
                return "Finish Workout"
            }
        }
        return "Finish"
    }

    private var finishButtonIcon: String {
        if viewModel.state == .resting {
            return "forward.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }

    private var finishButtonBackground: Color {
        if viewModel.state == .resting {
            return Color.blue.opacity(0.2)
        } else if viewModel.state == .running {
            if viewModel.currentSet < viewModel.numSets {
                return Color.green.opacity(0.2)
            } else {
                return Color("CardBackground")
            }
        }
        return Color("CardBackground")
    }

    private var finishButtonStroke: Color {
        if viewModel.state == .resting {
            return Color.blue.opacity(0.5)
        } else if viewModel.state == .running {
            if viewModel.currentSet < viewModel.numSets {
                return Color.green.opacity(0.5)
            } else {
                return accentColorForTimerType.opacity(0.5)
            }
        }
        return Color.secondary.opacity(0.3)
    }

    private var finishButtonAccessibilityLabel: String {
        if viewModel.state == .resting {
            return "Skip Rest Period"
        } else if viewModel.state == .running {
            if viewModel.currentSet < viewModel.numSets {
                return "Complete Set \(viewModel.currentSet) of \(viewModel.numSets)"
            } else {
                return "Finish Workout - Final Set"
            }
        }
        return "Finish Workout"
    }

    private var buttonAccessibilityLabel: String {
        switch viewModel.state {
        case .idle: return "Start Timer"
        case .countdown: return "Workout Starting"
        case .running: return "Pause Timer"
        case .paused: return "Resume Timer"
        case .resting: return "Resting"
        case .finished: return "Workout Finished"
        }
    }
}

// MARK: - Info Pill Component
struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color("CardBackground"))
                .overlay(
                    Capsule()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - RoundedCornerShape for specific corners
struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
