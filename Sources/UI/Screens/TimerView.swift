import SwiftUI
import UIKit

struct TimerView: View {
    @StateObject private var viewModel: TimerViewModel

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var areDetailsExpanded: Bool = true


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
            } else if viewModel.state == .countdown || viewModel.state == .countdownPaused {
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
        .onChange(of: viewModel.state) { newState in
            let isActive = newState != .idle && newState != .finished
            onWorkoutStateChange?(isActive)

            // Prevent screen from sleeping during active workouts
            // Enable idle timer only when idle or finished to allow normal sleep behavior
            UIApplication.shared.isIdleTimerDisabled = (newState != .idle && newState != .finished)

            // When workout finishes, create summary data and call callback
            if newState == .finished {
                let summaryData = createSummaryData(wasCompleted: true)
                onFinish?(summaryData)
            }
        }
        .onDisappear {
            // Re-enable idle timer when view disappears to restore normal behavior
            UIApplication.shared.isIdleTimerDisabled = false
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

            Text(viewModel.state == .countdownPaused ? "Paused" : "Get Ready")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .textCase(.uppercase)

            ZStack {
                Text(viewModel.countdownText)
                    .font(.system(size: horizontalSizeClass == .regular ? 240 : 120, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(accentColorForTimerType)
                    .accessibilityLabel("Starting in \(viewModel.countdownText) seconds")
                    .opacity(viewModel.state == .countdownPaused ? 0.3 : 1.0)
                
                if viewModel.state == .countdownPaused {
                    Image(systemName: "play.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
                }
            }

            Spacer()
        }
        .padding()
        .contentShape(Rectangle()) // Make full area tappable
        .onTapGesture {
            viewModel.toggleCountdownPause()
        }
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
                .foregroundColor(.blue)
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
        VStack(spacing: contentSpacing) {
                Spacer()
                    .frame(minHeight: topSpacerMinHeight)
                    .layoutPriority(0.2)

                // Time display with gradient
                VStack(spacing: 12) {
                    ZStack {
                        Text(viewModel.timeText)
                            .font(.system(size: mainTimerFontSize, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .opacity((viewModel.state == .idle || viewModel.state == .paused) ? 0.3 : 1.0) // Significantly dimmed when idle or paused
                            .saturation((viewModel.state == .idle || viewModel.state == .paused) ? 0.7 : 1.0)
                            .accessibilityLabel(viewModel.timerType == .amrap ? "Time Remaining: \(viewModel.timeText)" : "Elapsed Time: \(viewModel.timeText)")

                        // Play Icon Overlay
                        if viewModel.state == .idle || viewModel.state == .paused {
                            Image(systemName: "play.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
                        }
                    }


                }
                .contentShape(Rectangle()) // Make entire area tappable
                .onTapGesture {
                    if viewModel.state == .idle {
                        viewModel.startTapped()
                    } else if viewModel.state == .running {
                        viewModel.pauseTapped()
                    } else if viewModel.state == .paused {
                        viewModel.resumeTapped()
                    }
                }
                .accessibilityHint("Double tap to Start, Pause or Resume timer")

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
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Pacing Stats (Current vs Last Round)
                if viewModel.state == .running {
                    VStack(spacing: 8) {
                        if areDetailsExpanded {
                            HStack(spacing: 50) {
                                // Current Round Column
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

                                // Last Round Column
                                VStack(spacing: 6) {
                                    Text("Last Round")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)

                                    Text(viewModel.lastRoundSplitTime.map(formatTime) ?? "––:––")
                                        .font(.system(size: lastRoundFontSize, weight: .medium, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundColor(viewModel.lastRoundSplitTime != nil ? .white.opacity(0.8) : .white.opacity(0.4))

                                    // Delta indicator
                                    if let delta = viewModel.currentRoundVsLastDelta {
                                        Text(formatDelta(delta))
                                            .font(.system(size: deltaFontSize, weight: .medium))
                                            .foregroundColor(delta > 0 ? .orange : .green)
                                    } else {
                                        Text(" ")
                                            .font(.system(size: deltaFontSize, weight: .medium))
                                            .accessibilityHidden(true)
                                    }
                                }
                                .padding(.top, -6)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Pacing: Current Round \(viewModel.currentRoundTimeText). Last Round \(viewModel.lastRoundSplitTime.map(formatTime) ?? "None"). \(viewModel.currentRoundVsLastDelta.map { diff in diff > 0 ? "\(formatDeltaForVoiceOver(diff)) slower" : "\(formatDeltaForVoiceOver(diff)) faster" } ?? "")")
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Toggle Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                areDetailsExpanded.toggle()
                            }
                        }) {
                            Image(systemName: areDetailsExpanded ? "chevron.compact.up" : "chevron.compact.down")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.5))
                                .frame(width: 80, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(areDetailsExpanded ? "Collapse Pacing Details" : "Show Pacing Details")
                    }
                }

                // Round counter button (Always shown to allow round tracking)
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
                    .frame(maxWidth: buttonContainerMaxWidth)
                    .padding(.horizontal)
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
                .transition(.opacity)

                Spacer()
                    .layoutPriority(0.8)

                // Control buttons
                controlButtons

                Spacer()
                    .frame(height: bottomSpacerHeight)
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
        // iPad: 64 (33% of 192), iPhone: 32 (33% of 96) - reduced for better spacing
        horizontalSizeClass == .regular ? 64 : 32
    }

    private var lastRoundFontSize: CGFloat {
        // iPad: 44 (23% of 192), iPhone: 24 (25% of 96) - reduced for better spacing
        horizontalSizeClass == .regular ? 44 : 24
    }

    private var deltaFontSize: CGFloat {
        // iPad: 16, iPhone: 12
        horizontalSizeClass == .regular ? 16 : 12
    }

    // MARK: - Layout Spacing (Device & Timer-Type Adaptive)

    private var contentSpacing: CGFloat {
        // EMOM has additional vertical content (interval indicator)
        // requiring tighter spacing on smaller iPads to prevent overflow
        viewModel.timerType == .emom ? 16 : 20
    }

    private var bottomSpacerHeight: CGFloat {
        // Minimum bottom padding to keep controls in thumb zone
        // Increased for EMOM due to denser content stack
        viewModel.timerType == .emom ? 70 : 50
    }

    private var topSpacerMinHeight: CGFloat {
        // Reduced top spacer for EMOM to accommodate content density
        viewModel.timerType == .emom ? 40 : 60
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
        case .countdown, .countdownPaused:
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
        case .countdownPaused:
            return "Paused"
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
        VStack(spacing: 12) {
            // Complete Set / Skip Rest button (NOT shown when on final set - slider used instead)
            if !shouldShowFinishSlider {
                secondaryActionButton
            }

            // Full-width slide-to-finish (only on final set while running)
            if shouldShowFinishSlider {
                SlideToFinishButton(
                    label: "Slide to Finish",
                    icon: "flag.checkered",
                    accentColor: finishSliderColor
                ) {
                    viewModel.completeSetTapped()
                    let summaryData = createSummaryData(wasCompleted: false)
                    onFinish?(summaryData)
                }
            }
        }
        .frame(maxWidth: buttonContainerMaxWidth)
        .padding(.horizontal)
    }

    /// Whether to show the slide-to-finish slider (final set while running)
    private var shouldShowFinishSlider: Bool {
        viewModel.state == .running && viewModel.currentSet >= viewModel.numSets
    }

    /// Color for the finish slider based on timer type
    private var finishSliderColor: Color {
        switch viewModel.timerType {
        case .forTime:
            return .accentColor
        case .amrap:
            return .orange
        case .emom:
            return .red
        }
    }

    /// Secondary action button for Complete Set / Skip Rest
    private var secondaryActionButton: some View {
        Button(action: {
            if viewModel.state == .resting {
                viewModel.skipRest()
            } else if viewModel.state == .running {
                // Not final set - complete set and start rest
                viewModel.completeSetTapped()
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

    // MARK: - Computed Properties

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

// MARK: - SlideToFinishButton (Merged to fix build)
/// A slide-to-confirm button that prevents accidental activation of destructive actions.
/// Designed for ending workouts where accidental taps would be frustrating.
struct SlideToFinishButton: View {
    let label: String
    let icon: String
    let accentColor: Color
    let onComplete: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var hasCompleted: Bool = false
    @GestureState private var isPressed: Bool = false

    // Layout constants meeting accessibility requirements
    private let trackHeight: CGFloat = 60
    private let thumbSize: CGFloat = 52 // Meets 52pt minimum touch target
    private let thumbPadding: CGFloat = 4
    private let completionThreshold: CGFloat = 0.85 // 85% of track width to trigger

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let maxOffset = trackWidth - thumbSize - (thumbPadding * 2)
            let progress = min(dragOffset / maxOffset, 1.0)
            let isNearCompletion = progress >= completionThreshold

            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(trackBackgroundColor(progress: progress))
                    .overlay(
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .stroke(trackStrokeColor(progress: progress), lineWidth: 1)
                    )

                // Progress fill
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(progressFillColor(progress: progress))
                    .frame(width: thumbSize + dragOffset + thumbPadding)

                // Label text (fades as thumb approaches)
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 14, weight: .semibold))
                        Text(label)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(Double(1.0 - progress * 1.5)) // Fades out as slider progresses
                    Spacer()
                }
                .padding(.leading, thumbSize + thumbPadding * 2)

                // Thumb
                Circle()
                    .fill(thumbColor(progress: progress, isNearCompletion: isNearCompletion))
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Image(systemName: isNearCompletion ? "checkmark" : icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: accentColor.opacity(0.4), radius: isDragging ? 8 : 4, x: 0, y: 2)
                    .scaleEffect(isDragging ? 1.05 : 1.0)
                    .offset(x: thumbPadding + dragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !hasCompleted else { return }
                                isDragging = true
                                // Clamp offset between 0 and maxOffset
                                dragOffset = min(max(0, value.translation.width), maxOffset)
                            }
                            .onEnded { value in
                                isDragging = false
                                let finalProgress = dragOffset / maxOffset

                                if finalProgress >= completionThreshold {
                                    // Complete the action
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = maxOffset
                                        hasCompleted = true
                                    }

                                    // Haptic feedback
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)

                                    // Delay callback slightly for visual feedback
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onComplete()
                                    }
                                } else {
                                    // Spring back to start
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        dragOffset = 0
                                    }

                                    // Light haptic for reset
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            }
                    )
            }
            .frame(height: trackHeight)
        }
        .frame(height: trackHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)

        .accessibilityAction {
            // VoiceOver users can double-tap to activate
            onComplete()
        }
    }

    // MARK: - Color Helpers

    private func trackBackgroundColor(progress: CGFloat) -> Color {
        Color("CardBackground").opacity(0.8)
    }

    private func trackStrokeColor(progress: CGFloat) -> Color {
        if progress >= completionThreshold {
            return accentColor.opacity(0.8)
        }
        return accentColor.opacity(0.3 + progress * 0.3)
    }

    private func progressFillColor(progress: CGFloat) -> Color {
        if progress >= completionThreshold {
            return accentColor.opacity(0.4)
        }
        return accentColor.opacity(0.15 + progress * 0.2)
    }

    private func thumbColor(progress: CGFloat, isNearCompletion: Bool) -> LinearGradient {
        if isNearCompletion {
            return LinearGradient(
                colors: [accentColor, accentColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [accentColor.opacity(0.8), accentColor.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

