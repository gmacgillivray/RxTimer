import SwiftUI

private enum MainPresentationPhase {
    case home
    case activeWorkout
    case transitioning
    case summary
}

struct MainContainerView: View {
    // MARK: - State Management

    @State private var selectedTimerType: TimerType?
    @State private var showingConfiguration = false
    @State private var activeWorkoutConfig: TimerConfiguration?
    @State private var presentationPhase: MainPresentationPhase = .home
    @State private var workoutRestoredState: WorkoutState?
    @State private var summaryData: WorkoutSummaryData?
    @State private var pendingWorkoutSummary: WorkoutSummaryData?
    @State private var showingHistory = false

    var body: some View {
        TimerSelectionView(
            onSelectTimer: { timerType in
                selectedTimerType = timerType
                showingConfiguration = true
            },
            onNavigateToHistory: {
                showingHistory = true
            },
            onWorkoutComplete: handleWorkoutComplete,
            // Navigation bindings
            showingConfiguration: $showingConfiguration,
            selectedTimerType: $selectedTimerType
        )
        // Active workout full-screen cover (only used for state restoration)
        .fullScreenCover(isPresented: Binding(
            get: { presentationPhase == .activeWorkout },
            set: { if !$0 { presentationPhase = .home } }
        )) {
            if let config = activeWorkoutConfig {
                TimerView(
                    configuration: config,
                    restoredState: workoutRestoredState,
                    onWorkoutStateChange: { _ in },
                    onFinish: { summary in
                        summaryData = summary
                        presentationPhase = .transitioning

                        // Allow dismissal animation to complete before presenting summary
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            presentationPhase = .summary
                        }
                    }
                )
            }
        }
        // Summary full-screen cover (used when restoring state)
        .fullScreenCover(isPresented: Binding(
            get: { presentationPhase == .summary },
            set: { if !$0 { handleSummaryDismissed() } }
        )) {
            if let summary = summaryData {
                WorkoutSummaryView(
                    data: summary,
                    onDismiss: {
                        presentationPhase = .home
                        summaryData = nil
                        activeWorkoutConfig = nil
                        workoutRestoredState = nil
                    }
                )
            }
        }
        // Workout completion summary (from config views)
        .fullScreenCover(item: $pendingWorkoutSummary) { summary in
            WorkoutSummaryView(
                data: summary,
                onDismiss: {
                    pendingWorkoutSummary = nil
                    // Clean up config state
                    selectedTimerType = nil
                }
            )
        }
        // History full screen
        .fullScreenCover(isPresented: $showingHistory) {
            NavigationView {
                WorkoutHistoryView(
                    onSelectWorkout: { workout in
                        // Dismiss history when workout detail is implemented
                    }
                )
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
            workoutRestoredState = savedState
            activeWorkoutConfig = savedState.configuration
            presentationPhase = .activeWorkout
        }
    }

    private func handleSummaryDismissed() {
        if presentationPhase == .summary {
            presentationPhase = .home
            summaryData = nil
            activeWorkoutConfig = nil
            workoutRestoredState = nil
        }
    }

    private func handleWorkoutComplete(_ summary: WorkoutSummaryData) {
        // Dismiss config view first
        showingConfiguration = false

        // Schedule summary presentation after config dismisses
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pendingWorkoutSummary = summary
        }
    }
}
