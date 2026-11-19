import SwiftUI
import UIKit

struct TimerView: View {
    @StateObject private var viewModel: TimerViewModel

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var areDetailsExpanded: Bool = false
    @State private var timeDisplayPressed: Bool = false
    @State private var isWiderThanTall: Bool = false
    @State private var pausePulse: Bool = false
    @State private var showUndoToast: Bool = false
    @State private var undoToastRoundNumber: Int = 0
    @State private var undoToastSplitTime: TimeInterval?
    @State private var undoToastDelta: TimeInterval?
    @State private var undoToastWorkItem: DispatchWorkItem?


    let onWorkoutStateChange: ((Bool) -> Void)?
    let onFinish: ((WorkoutSummaryData) -> Void)?

    init(
        configuration: TimerConfiguration,
        restoredState: WorkoutState? = nil,
        startedTimer: TimerViewModel? = nil,
        onWorkoutStarted: ((TimerConfiguration) -> Void)? = nil,
        onWorkoutStateChange: ((Bool) -> Void)? = nil,
        onFinish: ((WorkoutSummaryData) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: startedTimer ?? TimerViewModel(
            configuration: configuration,
            restoredState: restoredState,
            onWorkoutStarted: onWorkoutStarted
        ))
        self.onWorkoutStateChange = onWorkoutStateChange
        self.onFinish = onFinish
    }

    var body: some View {
        GeometryReader { geo in
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

            // Undo toast overlay
            if showUndoToast {
                VStack {
                    if isIPadLandscape {
                        undoToastContent
                            .padding(.top, 60)
                        Spacer()
                    } else {
                        Spacer()
                        undoToastContent
                            .padding(.bottom, shouldShowFinishSlider ? 180 : 140)
                    }
                }
                .transition(.move(edge: isIPadLandscape ? .top : .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .onAppear { isWiderThanTall = geo.size.width > geo.size.height }
        .onChange(of: geo.size) { newSize in
            isWiderThanTall = newSize.width > newSize.height
        }
        } // GeometryReader
        .navigationTitle(viewModel.timerTypeDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.state != .idle)
        .preferredColorScheme(.dark)
        .overlay(alignment: .topLeading) {
            if viewModel.state != .idle && viewModel.state != .finished {
                Button(action: viewModel.finishTapped) {
                    Label("End early", systemImage: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .padding(.leading, 12)
                .accessibilityIdentifier("endWorkoutEarly")
            }
        }
        .onChange(of: viewModel.state) { newState in
            let isActive = newState != .idle && newState != .finished
            onWorkoutStateChange?(isActive)

            // Prevent screen from sleeping during active workouts
            // Enable idle timer only when idle or finished to allow normal sleep behavior
            UIApplication.shared.isIdleTimerDisabled = (newState != .idle && newState != .finished)
        }
        .onChange(of: viewModel.result) { result in
            if let result {
                onFinish?(result)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = viewModel.state != .idle && viewModel.state != .finished
        }
        .onDisappear {
            // Re-enable idle timer when view disappears to restore normal behavior
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func showRoundUndoToast(roundNumber: Int) {
        undoToastWorkItem?.cancel()
        undoToastRoundNumber = roundNumber
        undoToastSplitTime = viewModel.lastRoundSplitTime
        undoToastDelta = viewModel.currentRoundVsLastDelta
        withAnimation(.easeInOut(duration: 0.25)) {
            showUndoToast = true
        }
        let workItem = DispatchWorkItem { [self] in
            dismissUndoToast()
        }
        undoToastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    private func dismissUndoToast() {
        undoToastWorkItem?.cancel()
        undoToastWorkItem = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            showUndoToast = false
        }
    }

    // MARK: - Undo Toast Content
    private var undoToastContent: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Round \(undoToastRoundNumber) completed")
                    .font(.system(size: horizontalSizeClass == .regular ? 24 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    if let split = undoToastSplitTime {
                        Text(TimeFormatter.format(split))
                            .font(.system(size: horizontalSizeClass == .regular ? 20 : 16, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if let delta = undoToastDelta {
                        Text(TimeFormatter.formatDelta(delta))
                            .font(.system(size: horizontalSizeClass == .regular ? 18 : 14, weight: .medium, design: .rounded))
                            .foregroundColor(delta > 0 ? .red.opacity(0.9) : .green.opacity(0.9))
                    }
                }
            }
            Spacer()
            Button(action: {
                viewModel.undoLastRound()
                dismissUndoToast()
            }) {
                Text("Undo")
                    .font(.system(size: horizontalSizeClass == .regular ? 22 : 17, weight: .bold, design: .rounded))
                    .foregroundColor(accentColorForTimerType)
            }
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 20)
        .padding(.vertical, horizontalSizeClass == .regular ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: horizontalSizeClass == .regular ? 16 : 14)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
        .padding(.horizontal, 20)
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

            // Skip countdown hint
            if viewModel.state == .countdown {
                Button(action: {
                    viewModel.skipCountdown()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Tap to Skip")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .accessibilityLabel("Skip countdown and start workout")
            }

            Spacer()
                .frame(height: 40)
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
        Group {
            if isLandscape {
                landscapeTimerLayout
            } else if isIPadLandscape {
                iPadLandscapeTimerLayout
            } else {
                portraitTimerLayout
            }
        }
    }

    // MARK: - iPad Landscape Timer Layout
    /// Centers the clock on screen with controls overlaid at the bottom
    private var iPadLandscapeTimerLayout: some View {
        ZStack {
            // Centered clock with pacing stats below
            VStack(spacing: 12) {
                timeDisplayContent

                if viewModel.state == .running {
                    PacingStatsView(
                        currentRoundTimeText: viewModel.currentRoundTimeText,
                        lastRoundSplitTime: viewModel.lastRoundSplitTime,
                        currentRoundVsLastDelta: viewModel.currentRoundVsLastDelta,
                        accentColor: accentColorForTimerType,
                        currentRoundFontSize: currentRoundFontSize,
                        lastRoundFontSize: lastRoundFontSize,
                        deltaFontSize: deltaFontSize,
                        areDetailsExpanded: $areDetailsExpanded
                    )
                }
            }

            // Controls pinned to bottom
            VStack(spacing: 16) {
                Spacer()

                // Round counter button (full-width, matching portrait style)
                if viewModel.showCounterButton && viewModel.state == .running {
                    Button(action: {
                        viewModel.completeRound()
                        showRoundUndoToast(roundNumber: viewModel.roundCount)
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

                // Set/interval info
                secondaryInfoView

                controlButtons
                    .padding(.bottom, 20)
            }
        }
        .padding()
    }

    // MARK: - Landscape Timer Layout
    private var landscapeTimerLayout: some View {
        HStack(spacing: 24) {
            // Left side: time display
            VStack(spacing: 8) {
                Spacer()
                timeDisplayContent
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right side: controls and info
            VStack(spacing: 12) {
                Spacer()

                // Round counter (compact)
                if viewModel.showCounterButton && viewModel.state == .running {
                    Button(action: {
                        viewModel.completeRound()
                        showRoundUndoToast(roundNumber: viewModel.roundCount)
                    }) {
                        HStack(spacing: 8) {
                            Text("Round \(viewModel.roundCount + 1)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(accentColorForTimerType)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("CardBackground"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(accentColorForTimerType.opacity(0.4), lineWidth: 1.5)
                                )
                        )
                    }
                    .accessibilityLabel("Tap to complete round \(viewModel.roundCount + 1)")
                }

                // Secondary info
                secondaryInfoView

                Spacer()

                // Controls
                controlButtons

                Spacer()
                    .frame(height: 20)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }

    // MARK: - Portrait Timer Layout
    private var portraitTimerLayout: some View {
        VStack(spacing: contentSpacing) {
                Spacer()
                    .frame(minHeight: topSpacerMinHeight)
                    .layoutPriority(0.2)

                timeDisplayContent
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: areDetailsExpanded)

                // Pacing Stats (Current vs Last Round)
                if viewModel.state == .running {
                    PacingStatsView(
                        currentRoundTimeText: viewModel.currentRoundTimeText,
                        lastRoundSplitTime: viewModel.lastRoundSplitTime,
                        currentRoundVsLastDelta: viewModel.currentRoundVsLastDelta,
                        accentColor: accentColorForTimerType,
                        currentRoundFontSize: currentRoundFontSize,
                        lastRoundFontSize: lastRoundFontSize,
                        deltaFontSize: deltaFontSize,
                        areDetailsExpanded: $areDetailsExpanded
                    )
                }

                // Round counter button (Always shown to allow round tracking)
                if viewModel.showCounterButton && viewModel.state == .running {
                    Button(action: {
                        viewModel.completeRound()
                        showRoundUndoToast(roundNumber: viewModel.roundCount)
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
                            .accessibilityHidden(true)

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

    // MARK: - Shared Time Display Content
    private var timeDisplayContent: some View {
        VStack(spacing: 12) {
            ZStack {
                // Progress ring (thin, behind digits)
                if let progress = viewModel.progress, viewModel.state == .running {
                    Circle()
                        .stroke(accentColorForTimerType.opacity(0.15), lineWidth: 4)
                        .frame(width: progressRingSize, height: progressRingSize)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(accentColorForTimerType.opacity(0.6), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: progressRingSize, height: progressRingSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.25), value: progress)
                }

                Text(viewModel.timeText)
                    .font(.system(size: mainTimerFontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .opacity((viewModel.state == .idle || viewModel.state == .paused) ? 0.3 : 1.0)
                    .saturation((viewModel.state == .idle || viewModel.state == .paused) ? 0.7 : 1.0)
                    .accessibilityLabel(viewModel.timerType == .amrap ? "Time Remaining: \(viewModel.timeText)" : "Elapsed Time: \(viewModel.timeText)")

                // Play Icon Overlay (idle)
                if viewModel.state == .idle {
                    Image(systemName: "play.fill")
                        .font(.system(size: isLandscape ? 60 : 100))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
                }

                // Paused state: pulsing play icon + PAUSED label
                if viewModel.state == .paused {
                    VStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: isLandscape ? 50 : 80))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
                            .scaleEffect(pausePulse ? 1.1 : 0.95)
                            .opacity(pausePulse ? 1.0 : 0.6)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pausePulse)

                        Text("PAUSED")
                            .font(.system(size: isLandscape ? 16 : 20, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .tracking(2)
                    }
                    .onAppear { pausePulse = true }
                    .onDisappear { pausePulse = false }
                }
            }

            // "Tap to Start" hint in idle state
            if viewModel.state == .idle {
                Text("Tap to Start")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .transition(.opacity)
            }

            // AMRAP elapsed time
            if viewModel.timerType == .amrap && viewModel.state == .running {
                HStack(spacing: 6) {
                    Text("Elapsed:")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(viewModel.elapsedTimeText)
                        .font(.system(size: elapsedTimeFontSize, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.7))
                }
                .accessibilityLabel("Elapsed Time: \(viewModel.elapsedTimeText)")
            }

            // EMOM total elapsed
            if viewModel.timerType == .emom && viewModel.state == .running {
                HStack(spacing: 6) {
                    Text("Total:")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(viewModel.emomElapsedTimeText)
                        .font(.system(size: elapsedTimeFontSize, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.7))
                }
                .accessibilityLabel("Total Elapsed: \(viewModel.emomElapsedTimeText)")
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in timeDisplayPressed = true }
                .onEnded { value in
                    timeDisplayPressed = false
                    // Treat as tap if drag distance is small
                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    guard distance < 10 else { return }
                    if viewModel.state == .idle {
                        viewModel.startTapped()
                    } else if viewModel.state == .running {
                        viewModel.pauseTapped()
                    } else if viewModel.state == .paused {
                        viewModel.resumeTapped()
                    }
                }
        )
        .scaleEffect(timeDisplayPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: timeDisplayPressed)
        .accessibilityHint("Double tap to Start, Pause or Resume timer")
    }

    // MARK: - Secondary Info View
    private var secondaryInfoView: some View {
        VStack(spacing: 8) {
            if viewModel.numSets > 1 {
                InfoPill(
                    icon: "square.stack.3d.up.fill",
                    text: "Set \(viewModel.currentSet) of \(viewModel.numSets)"
                )
                .accessibilityLabel("Set \(viewModel.currentSet) of \(viewModel.numSets)")
            }

            if viewModel.timerType == .emom {
                InfoPill(
                    icon: "clock.fill",
                    text: "Interval \(viewModel.currentInterval) of \(viewModel.numIntervals)"
                )
            }
        }
    }

    /// True when iPhone is in landscape (compact vertical size class).
    /// iPad uses the portrait VStack layout in both orientations with adjusted spacers.
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    /// True when iPad is in landscape orientation (wider than tall)
    private var isIPadLandscape: Bool {
        horizontalSizeClass == .regular && isWiderThanTall
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
        if isLandscape { return 72 }
        if isIPadLandscape { return 300 }
        let expanded: CGFloat = horizontalSizeClass == .regular ? 192 : 96
        let collapsed: CGFloat = horizontalSizeClass == .regular ? 240 : 120
        if !areDetailsExpanded && viewModel.state == .running {
            return collapsed
        }
        return expanded
    }

    private var restTimerFontSize: CGFloat {
        // iPad: 240 (double), iPhone: 120
        horizontalSizeClass == .regular ? 240 : 120
    }

    private var progressRingSize: CGFloat {
        if isLandscape { return 100 }
        if isIPadLandscape { return 340 }
        let expanded: CGFloat = horizontalSizeClass == .regular ? 220 : 130
        let collapsed: CGFloat = horizontalSizeClass == .regular ? 270 : 160
        if !areDetailsExpanded && viewModel.state == .running {
            return collapsed
        }
        return expanded
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
