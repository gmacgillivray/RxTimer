import SwiftUI

// ViewModel is defined elsewhere

/// Main timer selection screen with adaptive layout
/// iPhone: Vertical card stack
/// iPad: Grid layout with optional recent workouts
struct TimerSelectionView: View {
    @StateObject private var viewModel: TimerSelectionViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Navigation state passed from parent
    @Binding var showingConfiguration: Bool
    @Binding var selectedTimerType: TimerType?

    // Callback for workout completion
    let onWorkoutComplete: (WorkoutSummaryData) -> Void
    let onStartWorkout: (TimerConfiguration) -> Void

    init(
        onSelectTimer: @escaping (TimerType) -> Void,
        onNavigateToHistory: @escaping () -> Void,
        onWorkoutComplete: @escaping (WorkoutSummaryData) -> Void,
        onStartWorkout: @escaping (TimerConfiguration) -> Void,
        showingConfiguration: Binding<Bool>,
        selectedTimerType: Binding<TimerType?>
    ) {
        self.onWorkoutComplete = onWorkoutComplete
        self.onStartWorkout = onStartWorkout
        _viewModel = StateObject(
            wrappedValue: TimerSelectionViewModel(
                onSelectTimer: onSelectTimer,
                onNavigateToHistory: onNavigateToHistory
            )
        )
        _showingConfiguration = showingConfiguration
        _selectedTimerType = selectedTimerType
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color("SecondaryBackground"), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    contentLayout
                        .padding(horizontalPadding)
                }

                // Hidden NavigationLinks for programmatic navigation
                navigationLinks
            }
            .navigationTitle("RxTimer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    historyButton
                }
            }
        }
        .navigationViewStyle(.stack) // P0: Force single-column layout on all devices
        .preferredColorScheme(.dark)
    }

    // MARK: - Navigation Links

    private var navigationLinks: some View {
        ZStack {
            // Configuration navigation
            if let timerType = selectedTimerType {
                NavigationLink(
                    destination: InlineConfigureTimerView(
                        timerType: timerType,
                        onStart: { config in
                            // Dismiss config view and start workout
                            showingConfiguration = false
                            selectedTimerType = nil
                            onStartWorkout(config)
                        },
                        onWorkoutComplete: onWorkoutComplete,
                        onCancel: {
                            showingConfiguration = false
                            selectedTimerType = nil
                        }
                    ),
                    isActive: $showingConfiguration
                ) {
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Layout

    @ViewBuilder
    private var contentLayout: some View {
        if isCompactWidth {
            iphoneLayout
        } else {
            ipadLayout
        }
    }

    // MARK: - iPhone Layout (Vertical Stack)

    private var iphoneLayout: some View {
        VStack(spacing: 24) {
            // Header text
            headerSection

            // Timer cards
            VStack(spacing: 16) {
                ForEach(TimerType.allCases, id: \.self) { timerType in
                    TimerTypeCard(
                        timerType: timerType,
                        configuration: viewModel.configuration(for: timerType),
                        onTap: {
                            viewModel.selectTimer(timerType)
                        }
                    )
                }
            }

            // Recent workout preview (if available)
            if let recent = viewModel.mostRecentWorkout {
                recentWorkoutCard(recent)
            }

            // Footer spacing
            Spacer()
                .frame(height: 40)
        }
        .padding(.top, 8)
    }

    // MARK: - iPad Layout (Grid)

    private var ipadLayout: some View {
        VStack(spacing: 32) {
            // Header text
            headerSection
                .padding(.horizontal, 8) // Align with grid

            // Timer cards in grid
            LazyVGrid(
                columns: gridColumns, // P1: Adaptive columns (3 for large iPads, 2 for mini)
                spacing: 24 // P1: Increased spacing for better touch targets
            ) {
                ForEach(TimerType.allCases, id: \.self) { timerType in
                    TimerTypeCard(
                        timerType: timerType,
                        configuration: viewModel.configuration(for: timerType),
                        onTap: {
                            viewModel.selectTimer(timerType)
                        }
                    )
                    .frame(maxHeight: 320) // P1: Constrain card height for better proportions
                }
            }

            // Recent workouts section
            if let recent = viewModel.mostRecentWorkout {
                recentWorkoutsSection(recent)
            }

            Spacer()
                .frame(height: 40)
        }
        .padding(.top, 8)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Timer")
                .font(.system(
                    size: isCompactWidth ? 32 : 44, // P2: Larger on iPad
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)

            Text("Tap to configure a timer")
                .font(.system(
                    size: isCompactWidth ? 16 : 19, // P2: Scale subtitle too
                    weight: .medium
                ))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - History Button

    private var historyButton: some View {
        Button(action: viewModel.navigateToHistory) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(
                    size: isCompactWidth ? 18 : 22, // P2: Larger icon on iPad
                    weight: .semibold
                ))
                .foregroundColor(.white)
                .frame(
                    width: isCompactWidth ? 44 : 52, // P2: Larger touch target on iPad
                    height: isCompactWidth ? 44 : 52
                )
        }
        .accessibilityLabel("Workout History")
        .accessibilityHint("View past workouts")
    }

    // MARK: - Recent Workout Card

    private func recentWorkoutCard(_ workout: WorkoutSummaryData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple.opacity(0.8))

                Text("MOST RECENT")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.purple.opacity(0.8))
                    .tracking(0.5)

                Spacer()

                Button(action: viewModel.navigateToHistory) {
                    Text("View All")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.purple)
                }
                .accessibilityLabel("View all workout history")
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Workout summary
            HStack(spacing: 16) {
                // Timer type icon
                ZStack {
                    Circle()
                        .fill(timerColor(for: workout.configuration.timerType).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: timerIcon(for: workout.configuration.timerType))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(timerColor(for: workout.configuration.timerType))
                }

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.configuration.timerType.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(formatWorkoutSummary(workout))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Timestamp
                Text(formatRelativeTime(workout.timestamp))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Most recent workout: \(workout.configuration.timerType.displayName), \(formatWorkoutSummary(workout)), \(formatRelativeTime(workout.timestamp))")
    }

    // MARK: - Recent Workouts Section (iPad)

    private func recentWorkoutsSection(_ workout: WorkoutSummaryData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.purple.opacity(0.8))

                Text("RECENT WORKOUTS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.purple.opacity(0.8))
                    .tracking(0.5)

                Spacer()

                Button(action: viewModel.navigateToHistory) {
                    HStack(spacing: 6) {
                        Text("View All")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.purple)
                }
                .accessibilityLabel("View all workout history")
            }

            recentWorkoutCard(workout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    /// P2: Detect large iPads (11" and 12.9") vs iPad mini
    private var isLargeIpad: Bool {
        !isCompactWidth && UIScreen.main.bounds.width > 900
    }

    /// P1: Responsive padding that scales with screen width on iPad
    private var horizontalPadding: CGFloat {
        if isCompactWidth {
            return 20
        } else {
            // iPad: Scale padding with screen width
            // 11" iPad (~834pt): ~67pt
            // 12.9" iPad (~1024pt): ~82pt
            // Max: 120pt for very large displays
            return max(60, min(120, UIScreen.main.bounds.width * 0.08))
        }
    }

    /// P2: Adaptive grid columns - 3 for large iPads, 2 for iPad mini
    private var gridColumns: [GridItem] {
        if isLargeIpad {
            // iPad 11" and 12.9": 3 columns for visual balance
            return Array(repeating: GridItem(.flexible(), spacing: 24), count: 3)
        } else {
            // iPad mini: 2 columns (fallback for small tablets ~810pt)
            return Array(repeating: GridItem(.flexible(), spacing: 24), count: 2)
        }
    }

    private func timerIcon(for timerType: TimerType) -> String {
        switch timerType {
        case .forTime: return "stopwatch"
        case .amrap: return "flame.fill"
        case .emom: return "clock.arrow.circlepath"
        }
    }

    private func timerColor(for timerType: TimerType) -> Color {
        switch timerType {
        case .forTime: return Color("AccentColor")
        case .amrap: return .orange
        case .emom: return .blue
        }
    }

    private func formatWorkoutSummary(_ workout: WorkoutSummaryData) -> String {
        let totalSeconds = Int(workout.duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        let durationString = seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"

        // Add set information if multi-set
        let setCount = workout.setDurations.count
        if setCount > 1 {
            return "\(durationString) • \(setCount) sets"
        }

        return durationString
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#if DEBUG
struct TimerSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone
            PreviewWrapper()
                .previewDevice("iPhone 15 Pro")
                .previewDisplayName("iPhone")

            // iPad
            PreviewWrapper()
                .previewDevice("iPad Pro 13-inch (M5)")
                .previewDisplayName("iPad")
        }
        .preferredColorScheme(.dark)
    }

    struct PreviewWrapper: View {
        @State private var showingConfiguration = false
        @State private var selectedTimerType: TimerType?

        var body: some View {
            TimerSelectionView(
                onSelectTimer: { _ in },
                onNavigateToHistory: { },
                onWorkoutComplete: { _ in },
                onStartWorkout: { _ in },
                showingConfiguration: $showingConfiguration,
                selectedTimerType: $selectedTimerType
            )
        }
    }
}
#endif
