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
    
    // Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme

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
            VStack(spacing: 0) {
                // Header
                ConfigurationHeader(
                    title: timerType.displayName,
                    subtitle: subtitle,
                    iconName: iconName,
                    iconColor: iconColor
                )
                .padding(.bottom)
                .background(Color(UIColor.systemGroupedBackground)) // Ensure opacity

                // Scrollable Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Specific Settings
                        switch timerType {
                        case .forTime:
                            forTimeSection
                        case .amrap:
                            amrapSection
                        case .emom:
                            emomSection
                        }
                        
                        // Common Settings
                        multiSetSection
                        
                        // Bottom spacer for sticky button
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            
            // Sticky Footer
            VStack {
                Spacer()
                StickyStartButton(action: startWorkout, color: iconColor)
            }
        }
        .background(
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
        )
        .navigationTitle("Configure Timer")
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
                    finishWorkout(summary)
                }
            )
        }
    }

    // MARK: - Actions
    
    private func startWorkout() {
        saveConfiguration()
        presentationPhase = .workout
    }
    
    private func finishWorkout(_ summary: WorkoutSummaryData) {
        presentationPhase = .configuration
        onWorkoutComplete(summary)
        
        // Dismiss this config view after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - Dismissal Handlers

    private func handleWorkoutDismissed() {
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

    // MARK: - View Components

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
    private var forTimeSection: some View {
        ConfigurationCard(title: "Time Cap") {
            InlineOptionalTimePicker(
                title: "Time Cap",
                selection: Binding(
                    get: { configuration.timeCapSeconds },
                    set: { configuration.timeCapSeconds = $0 }
                )
            )
        }
    }

    // MARK: - AMRAP Settings
    private var amrapSection: some View {
        ConfigurationCard(title: "Work Duration") {
            InlineTimePicker(
                title: "Duration",
                selection: Binding(
                    get: { configuration.durationSeconds ?? 600 },
                    set: { configuration.durationSeconds = $0 }
                )
            )
        }
    }

    // MARK: - EMOM Settings
    private var emomSection: some View {
        ConfigurationCard(title: "Work Intervals") {
            VStack(spacing: 16) {
                BigStepper(
                    title: "Intervals",
                    value: Binding(
                        get: { configuration.numIntervals ?? 10 },
                        set: { configuration.numIntervals = $0 }
                    ),
                    range: 1...60,
                    color: iconColor
                )
                
                Divider()
                
                InlineTimePicker(
                    title: "Interval Duration",
                    selection: Binding(
                        get: { configuration.intervalDurationSeconds ?? 60 },
                        set: { configuration.intervalDurationSeconds = $0 }
                    )
                )
                
                if let total = configuration.totalDurationSeconds {
                    Divider()
                    HStack {
                        Text("Total Workout Time")
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        Spacer()
                        Text(formatSeconds(total))
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Multi-Set Settings
    private var multiSetSection: some View {
        ConfigurationCard(title: "Sets & Rest") {
            VStack(spacing: 16) {
                BigStepper(
                    title: "Sets",
                    value: Binding(
                        get: { configuration.numSets },
                        set: { newValue in
                            configuration.numSets = newValue
                            if newValue > 1 && configuration.restDurationSeconds == nil {
                                configuration.restDurationSeconds = 120
                            }
                        }
                    ),
                    range: 1...10,
                    color: iconColor
                )

                if configuration.numSets > 1 {
                    Divider()
                    InlineTimePicker(
                        title: "Rest Between Sets",
                        selection: Binding(
                            get: { configuration.restDurationSeconds ?? 120 },
                            set: { configuration.restDurationSeconds = $0 }
                        )
                    )
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
}

// MARK: - New Components

struct ConfigurationHeader: View {
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(iconColor)
                .clipShape(Circle())
                .shadow(color: iconColor.opacity(0.4), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ConfigurationCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            VStack {
                content
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct StickyStartButton: View {
    let action: () -> Void
    let color: Color

    var body: some View {
        VStack {
            Button(action: action) {
                Text("Start Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(color)
                    .cornerRadius(16)
                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .padding()
        .background(
            Color(UIColor.systemGroupedBackground)
                .opacity(0.9)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Inline Components

struct InlineTimePicker: View {
    let title: String
    @Binding var selection: Int
    @State private var isExpanded: Bool = false
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header (Always Visible)
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .foregroundColor(.primary)
                    Spacer()
                    HStack {
                        Text(formatSeconds(selection))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle()) // Make full width tappable
            }
            .buttonStyle(.plain)

            // Expanded Content
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                    HStack {
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<100) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .clipped()

                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { sec in
                                Text("\(sec) sec").tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    }
                    .frame(height: 150)
                }
                .onAppear {
                    syncWheels(from: selection)
                }
                .onChange(of: selection) { newValue in
                    syncWheels(from: newValue)
                }
                .onChange(of: minutes) { _ in updateSelection() }
                .onChange(of: seconds) { _ in updateSelection() }
            }
        }
    }

    private func syncWheels(from totalSeconds: Int) {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        if minutes != mins || seconds != secs {
            minutes = mins
            seconds = secs
        }
    }

    private func updateSelection() {
        let totalSeconds = (minutes * 60) + seconds
        if selection != totalSeconds {
            selection = totalSeconds
        }
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(mins) min"
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
}

struct InlineOptionalTimePicker: View {
    let title: String
    @Binding var selection: Int?
    @State private var isExpanded: Bool = false
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .foregroundColor(.primary)
                    Spacer()
                    HStack {
                        if let val = selection {
                            Text(formatSeconds(val))
                        } else {
                            Text("No Time Cap")
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded Content
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                    
                    // No Time Cap Toggle
                    Toggle("No Time Cap", isOn: Binding(
                        get: { selection == nil },
                        set: { isNone in
                            if isNone {
                                selection = nil
                            } else {
                                // Default to 20 mins if re-enabling
                                selection = (minutes * 60) + seconds
                                if selection == 0 { selection = 1200; syncWheels(from: 1200) }
                            }
                        }
                    ))
                    
                    if selection != nil {
                        HStack {
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<100) { min in
                                    Text("\(min) min").tag(min)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            .clipped()

                            Picker("Seconds", selection: $seconds) {
                                ForEach(0..<60) { sec in
                                    Text("\(sec) sec").tag(sec)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            .clipped()
                        }
                        .frame(height: 150)
                    }
                }
                .onAppear {
                    syncWheels(from: selection)
                }
                .onChange(of: selection) { newValue in
                    syncWheels(from: newValue)
                }
                .onChange(of: minutes) { _ in updateSelection() }
                .onChange(of: seconds) { _ in updateSelection() }
            }
        }
    }

    private func syncWheels(from selection: Int?) {
        if let totalSeconds = selection {
            let mins = totalSeconds / 60
            let secs = totalSeconds % 60
            if minutes != mins || seconds != secs {
                minutes = mins
                seconds = secs
            }
        }
    }

    private func updateSelection() {
        guard selection != nil else { return } // Don't update if disabled
        
        let totalSeconds = (minutes * 60) + seconds
        if selection != totalSeconds {
            selection = totalSeconds
        }
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(mins) min"
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
}

struct BigStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(value > range.lowerBound ? color : .gray.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .frame(minWidth: 30)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Button(action: {
                    if value < range.upperBound {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(value < range.upperBound ? color : .gray.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.vertical, 4)
    }
}
