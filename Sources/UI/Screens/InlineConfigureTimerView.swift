import SwiftUI

private enum PresentationPhase {
    case configuration
    case workout
}

struct InlineConfigureTimerView: View {
    let timerType: TimerType
    let onStart: (TimerConfiguration) -> Void
    let onWorkoutComplete: (WorkoutSummaryData) -> Void
    let onCancel: () -> Void

    @State private var configuration: TimerConfiguration
    @State private var presentationPhase: PresentationPhase = .configuration
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode

    init(
        timerType: TimerType,
        onStart: @escaping (TimerConfiguration) -> Void,
        onWorkoutComplete: @escaping (WorkoutSummaryData) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.timerType = timerType
        self.onStart = onStart
        self.onWorkoutComplete = onWorkoutComplete
        self.onCancel = onCancel

        // Initialize with appropriate defaults for each timer type
        var config = TimerConfiguration(timerType: timerType)
        switch timerType {
        case .amrap:
            config.durationSeconds = 600 // Default 10 minutes
        case .emom:
            config.numIntervals = 10
            config.intervalDurationSeconds = 60
        case .forTime:
            break // No required defaults
        }
        _configuration = State(initialValue: config)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color("SecondaryBackground"), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: iconName)
                            .font(.system(size: isCompactWidth ? 60 : 72))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [iconColor, iconColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, isCompactWidth ? 40 : 24)

                        Text("Configure \(timerType.displayName)")
                            .font(.system(
                                size: isCompactWidth ? 32 : 40,
                                weight: .bold,
                                design: .rounded
                            ))
                            .foregroundColor(.white)

                        Text(subtitle)
                            .font(.system(size: isCompactWidth ? 16 : 19))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)

                    // Configuration options
                    VStack(spacing: 16) {
                        switch timerType {
                        case .forTime:
                            forTimeSettings
                        case .amrap:
                            amrapSettings
                        case .emom:
                            emomSettings
                        }

                        multiSetSettings
                    }
                    .padding(.horizontal, horizontalPadding)
                    .frame(maxWidth: isCompactWidth ? .infinity : 700)

                    // Start button
                    Button(action: {
                        // Save configuration for future use
                        saveConfiguration()

                        // Present workout directly from this view
                        presentationPhase = .workout
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: isCompactWidth ? 24 : 28))
                            Text("Start Workout")
                                .font(.system(
                                    size: isCompactWidth ? 20 : 24,
                                    weight: .bold,
                                    design: .rounded
                                ))
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: isCompactWidth ? 64 : 72
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [iconColor, iconColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: iconColor.opacity(0.4), radius: 15, x: 0, y: 8)
                        )
                        .foregroundColor(.white)
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, horizontalPadding)
                    .frame(maxWidth: isCompactWidth ? .infinity : 700)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Configure \(timerType.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: Binding(
            get: { presentationPhase == .workout },
            set: { if !$0 { handleWorkoutDismissed() } }
        )) {
            TimerView(
                configuration: configuration,
                restoredState: nil,
                onWorkoutStateChange: { _ in },
                onFinish: { summary in
                    // Dismiss workout and return to config
                    presentationPhase = .configuration

                    // Notify parent to present summary
                    onWorkoutComplete(summary)

                    // Dismiss this config view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }

    // MARK: - Dismissal Handlers

    private func handleWorkoutDismissed() {
        // User manually dismissed workout (swipe down on iOS 15+)
        if presentationPhase == .workout {
            presentationPhase = .configuration
        }
    }

    // MARK: - Configuration Persistence

    private func saveConfiguration() {
        let key = "LastUsedConfig.\(configuration.timerType.rawValue)"
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }

    private var iconName: String {
        switch timerType {
        case .forTime: return "stopwatch"
        case .amrap: return "flame.fill"
        case .emom: return "clock.arrow.circlepath"
        }
    }

    private var iconColor: Color {
        switch timerType {
        case .forTime: return .accentColor
        case .amrap: return .orange
        case .emom: return .blue
        }
    }

    private var subtitle: String {
        switch timerType {
        case .forTime: return "Count up with optional time cap"
        case .amrap: return "As Many Rounds As Possible"
        case .emom: return "Every Minute On the Minute"
        }
    }

    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    private var horizontalPadding: CGFloat {
        if isCompactWidth {
            return 20
        } else {
            return max(60, min(120, UIScreen.main.bounds.width * 0.08))
        }
    }

    // MARK: - For Time Settings
    private var forTimeSettings: some View {
        VStack(spacing: 12) {
            ConfigCard {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { configuration.timeCapSeconds != nil },
                        set: { enabled in
                            configuration.timeCapSeconds = enabled ? 1200 : nil
                        }
                    )) {
                        Label("Time Cap", systemImage: "timer")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .tint(iconColor)

                    if configuration.timeCapSeconds != nil {
                        Picker("Duration", selection: Binding(
                            get: { configuration.timeCapSeconds ?? 1200 },
                            set: { configuration.timeCapSeconds = $0 }
                        )) {
                            ForEach([180, 300, 600, 900, 1200, 1500, 1800], id: \.self) { seconds in
                                Text(formatSeconds(seconds)).tag(seconds)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }

    // MARK: - AMRAP Settings
    private var amrapSettings: some View {
        ConfigCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Duration", systemImage: "clock")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                Picker("Duration", selection: Binding(
                    get: { configuration.durationSeconds ?? 600 },
                    set: { configuration.durationSeconds = $0 }
                )) {
                    ForEach(getAMRAPDurations(), id: \.self) { seconds in
                        Text(formatSeconds(seconds)).tag(seconds)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
            }
        }
    }

    // MARK: - EMOM Settings
    private var emomSettings: some View {
        VStack(spacing: 12) {
            ConfigCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Number of Intervals", systemImage: "number")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))

                    Stepper(value: Binding(
                        get: { configuration.numIntervals ?? 10 },
                        set: { configuration.numIntervals = $0 }
                    ), in: 1...60) {
                        Text("\(configuration.numIntervals ?? 10) intervals")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(iconColor)
                    }
                }
            }

            ConfigCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Interval Duration", systemImage: "timer")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))

                    Picker("Interval Duration", selection: Binding(
                        get: { configuration.intervalDurationSeconds ?? 60 },
                        set: { configuration.intervalDurationSeconds = $0 }
                    )) {
                        ForEach(getEMOMIntervals(), id: \.self) { seconds in
                            Text(formatSeconds(seconds)).tag(seconds)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }
            }

            if let total = configuration.totalDurationSeconds {
                Text("Total: \(formatSeconds(total))")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Multi-Set Settings
    private var multiSetSettings: some View {
        VStack(spacing: 12) {
            ConfigCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Number of Sets", systemImage: "square.stack.3d.up.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))

                    Stepper(value: Binding(
                        get: { configuration.numSets },
                        set: { newValue in
                            configuration.numSets = newValue

                            // Auto-initialize rest to 120 seconds when enabling multi-set
                            if newValue > 1 && configuration.restDurationSeconds == nil {
                                configuration.restDurationSeconds = 120
                            }
                        }
                    ), in: 1...10) {
                        Text("\(configuration.numSets) \(configuration.numSets == 1 ? "set" : "sets")")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(iconColor)
                    }
                }
            }

            if configuration.numSets > 1 {
                ConfigCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Rest Between Sets", systemImage: "pause.circle")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))

                        Picker("Rest Duration", selection: Binding(
                            get: { configuration.restDurationSeconds ?? 120 },
                            set: { configuration.restDurationSeconds = $0 }
                        )) {
                            ForEach(getRestDurations(), id: \.self) { seconds in
                                Text(formatSeconds(seconds)).tag(seconds)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func formatSeconds(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(mins) min"
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }

    private func getAMRAPDurations() -> [Int] {
        var durations: [Int] = []
        for i in 1...10 { durations.append(i * 60) }
        for i in 6...10 { durations.append(i * 120) }
        for i in 5...12 { durations.append(i * 300) }
        return durations
    }

    private func getEMOMIntervals() -> [Int] {
        [15, 30, 45, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360, 390, 420, 450, 480, 510, 540, 570, 600]
    }

    private func getRestDurations() -> [Int] {
        var durations: [Int] = []
        for i in 1...8 { durations.append(i * 15) }
        for i in 5...10 { durations.append(i * 30) }
        for i in 6...10 { durations.append(i * 60) }
        return durations
    }
}

// MARK: - Config Card
struct ConfigCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}
