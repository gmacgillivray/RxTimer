import SwiftUI

struct InlineConfigureTimerView: View {
    let timerType: TimerType
    let onStart: (TimerConfiguration) -> Void
    let onCancel: () -> Void

    @State private var configuration: TimerConfiguration

    init(
        timerType: TimerType,
        onStart: @escaping (TimerConfiguration) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.timerType = timerType
        self.onStart = onStart
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
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [iconColor, iconColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 40)

                        Text("Configure \(timerType.displayName)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(subtitle)
                            .font(.system(size: 16))
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
                    .padding(.horizontal, 20)

                    // Start button
                    Button(action: {
                        // Simple callback - parent handles navigation
                        onStart(configuration)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                            Text("Start Workout")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: 400, minHeight: 64)
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

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Configure \(timerType.displayName)")
        .navigationBarTitleDisplayMode(.inline)
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

                    Stepper(value: $configuration.numSets, in: 1...10) {
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
