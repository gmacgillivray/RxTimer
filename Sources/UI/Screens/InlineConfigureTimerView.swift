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
    
    // Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme

    init(
        configuration: TimerConfiguration,
        onStart: @escaping (TimerConfiguration) -> Void,
        onWorkoutComplete: @escaping (WorkoutSummaryData) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.timerType = configuration.timerType
        self.onStart = onStart
        self.onWorkoutComplete = onWorkoutComplete
        self.onCancel = onCancel

        _configuration = State(initialValue: configuration)
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
                    .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity) // Center the constrained content
                }
            }
            
            // Sticky Footer
            VStack {
                Spacer()
                StickyStartButton(action: startWorkout, color: iconColor)
                    .disabled(!configuration.isUsable)
            }
        }
        .background(
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
        )
        .navigationTitle("Configure Timer")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", action: onCancel)
            }
        }
    }

    // MARK: - Actions
    
    private func startWorkout() {
        onStart(configuration)
    }
    
    private func finishWorkout(_ summary: WorkoutSummaryData) {
        onWorkoutComplete(summary)
        presentationMode.wrappedValue.dismiss()
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
                            .font(horizontalSizeClass == .regular ? .system(size: 20, weight: .medium) : .body.weight(.medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(formatSeconds(total))
                            .font(horizontalSizeClass == .regular ? .system(size: 18, weight: .medium) : .body.weight(.medium))
                            .foregroundColor(.secondary)
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
                            get: { configuration.restDurationSeconds ?? 0 },
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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        HStack(spacing: isIPad ? 24 : 20) {
            Image(systemName: iconName)
                .font(.system(size: isIPad ? 50 : 40))
                .foregroundColor(.white)
                .frame(width: isIPad ? 85 : 70, height: isIPad ? 85 : 70)
                .background(iconColor)
                .clipShape(Circle())
                .shadow(color: iconColor.opacity(0.4), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(isIPad ? .title : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(isIPad ? .body : .subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal)
        .frame(maxWidth: isIPad ? 600 : .infinity, alignment: .leading)
    }
}

struct ConfigurationCard<Content: View>: View {
    let title: String
    let content: Content

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(isIPad ? .footnote.weight(.bold) : .caption.weight(.bold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack {
                content
            }
            .padding(isIPad ? 20 : 16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct StickyStartButton: View {
    let action: () -> Void
    let color: Color

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        VStack {
            Button(action: action) {
                Text("Start Workout")
                    .font(isIPad ? .title3.weight(.semibold) : .headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: isIPad ? 600 : .infinity)
                    .padding(isIPad ? 18 : 16)
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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

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
                        .font(isIPad ? .system(size: 20, weight: .medium) : .body)
                        .foregroundColor(.primary)
                    Spacer()
                    HStack {
                        Text(formatSeconds(selection))
                            .font(isIPad ? .system(size: 18) : .body)
                        Image(systemName: "chevron.right")
                            .font(isIPad ? .footnote : .caption)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, isIPad ? 12 : 8)
                .contentShape(Rectangle())
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
                    .frame(height: isIPad ? 180 : 150)
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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

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
                        .font(isIPad ? .system(size: 20, weight: .medium) : .body)
                        .foregroundColor(.primary)
                    Spacer()
                    HStack {
                        if let val = selection {
                            Text(formatSeconds(val))
                                .font(isIPad ? .system(size: 18) : .body)
                        } else {
                            Text("No Time Cap")
                                .font(isIPad ? .system(size: 18) : .body)
                        }
                        Image(systemName: "chevron.right")
                            .font(isIPad ? .footnote : .caption)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, isIPad ? 12 : 8)
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
                        .frame(height: isIPad ? 180 : 150)
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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        if isIPad {
            // iPad: vertical layout keeps label and controls grouped
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)

                HStack(spacing: 24) {
                    Button(action: {
                        if value > range.lowerBound { value -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(value > range.lowerBound ? color : .gray.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Decrease \(title)")
                    .disabled(value <= range.lowerBound)

                    Text("\(value)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .frame(minWidth: 40)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)

                    Button(action: {
                        if value < range.upperBound { value += 1 }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(value < range.upperBound ? color : .gray.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Increase \(title)")
                    .disabled(value >= range.upperBound)
                }
            }
            .padding(.vertical, 8)
        } else {
            // iPhone: horizontal layout
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 20) {
                    Button(action: {
                        if value > range.lowerBound { value -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(value > range.lowerBound ? color : .gray.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Decrease \(title)")
                    .disabled(value <= range.lowerBound)

                    Text("\(value)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .frame(minWidth: 30)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)

                    Button(action: {
                        if value < range.upperBound { value += 1 }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(value < range.upperBound ? color : .gray.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Increase \(title)")
                    .disabled(value >= range.upperBound)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
