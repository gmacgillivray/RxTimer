import SwiftUI

struct MainContainerView: View {
    // ViewModel managing navigation and Quick Start
    @StateObject private var viewModel = MainContainerViewModel()
    @State private var isWorkoutActive = false

    var body: some View {
        NavigationView {
            // Sidebar with timer list
            timerListView
                .navigationTitle("Workout Timer")
                .navigationBarTitleDisplayMode(.large)

            // Content pane (detail view on iPad, push destination on iPhone)
            contentPane
        }
        .overlay(alignment: .top) {
            if viewModel.isCountingDown {
                QuickStartCountdownToast(
                    seconds: viewModel.countdownSeconds,
                    onCancel: { viewModel.cancelQuickStart() }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isCountingDown)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            checkForStateRestoration()
        }
    }

    private func checkForStateRestoration() {
        if let savedState = WorkoutStateManager.shared.loadState() {
            // Restore the workout
            viewModel.navigationState = .activeWorkout(savedState.configuration, restoredState: savedState)
            isWorkoutActive = true
        }
    }

    @ViewBuilder
    private var timerListView: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color("SecondaryBackground"), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            List {
                Section {
                    ForEach(TimerType.allCases, id: \.self) { timerType in
                        SidebarTimerRow(
                            timerType: timerType,
                            isSelected: isSelected(timerType),
                            onTap: {
                                // Navigate to configuration for selected timer
                                viewModel.navigationState = .configuration(timerType)
                            },
                            onQuickStart: {
                                // Start Quick Start countdown
                                viewModel.initiateQuickStart(for: timerType)
                            },
                            quickStartLabel: viewModel.quickStartAccessibilityLabel(for: timerType)
                        )
                        .disabled(isWorkoutActive)
                        .opacity(isWorkoutActive ? 0.5 : 1.0)
                    }
                } header: {
                    Text("Timer Types")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button(action: {
                        // Navigate to history
                        viewModel.navigationState = .history
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.purple)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("History")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("View past workouts")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isWorkoutActive)
                    .opacity(isWorkoutActive ? 0.5 : 1.0)
                } header: {
                    Text("Other")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .background(Color.clear)
            .listStyle(.sidebar)
        }
    }

    @ViewBuilder
    private var contentPane: some View {
        switch viewModel.navigationState {
        case .home:
            // Empty state - timer selection
            EmptyStateView()

        case .configuration(let timerType):
            // Configuring timer
            InlineConfigureTimerView(
                timerType: timerType,
                onStart: { config in
                    // Save configuration for future Quick Start
                    viewModel.saveConfiguration(config)

                    // Start workout - transition to active workout state
                    viewModel.navigationState = .activeWorkout(config, restoredState: nil)
                    isWorkoutActive = true
                },
                onCancel: {
                    // Return to home
                    viewModel.navigationState = .home
                }
            )

        case .activeWorkout(let config, let restoredState):
            // Active workout
            TimerView(
                configuration: config,
                restoredState: restoredState,
                onWorkoutStateChange: { isActive in
                    isWorkoutActive = isActive
                },
                onFinish: { summaryData in
                    // Workout finished - transition to summary state
                    viewModel.navigationState = .summary(summaryData)
                    isWorkoutActive = false
                }
            )

        case .summary(let data):
            // Workout summary
            WorkoutSummaryView(
                data: data,
                onDismiss: {
                    // Return to home - single line!
                    viewModel.navigationState = .home
                }
            )

        case .history:
            // Workout history list
            WorkoutHistoryView(
                onSelectWorkout: { workout in
                    // Navigate to workout detail
                    viewModel.navigationState = .historyDetail(workout)
                }
            )

        case .historyDetail(let workout):
            // Workout detail from history
            WorkoutDetailView(
                workout: workout,
                onDismiss: {
                    // Return to history list
                    viewModel.navigationState = .history
                }
            )
        }
    }

    // Helper to determine if a timer type is currently selected
    private func isSelected(_ timerType: TimerType) -> Bool {
        switch viewModel.navigationState {
        case .configuration(let selectedType):
            return selectedType == timerType
        case .activeWorkout(let config, _):
            return config.timerType == timerType
        default:
            return false
        }
    }

    // Helper to determine if history is currently selected
    private var isHistorySelected: Bool {
        switch viewModel.navigationState {
        case .history, .historyDetail:
            return true
        default:
            return false
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("SecondaryBackground"), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)

                Text("Select a Timer Type")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Choose from the sidebar to begin")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
    }
}
