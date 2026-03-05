import SwiftUI

struct MainContainerView: View {
    // MARK: - State Management (Single source of truth)
    @State private var navState: AppNavigationState = .home

    // Transient data carried between navigation states
    @State private var pendingWorkoutSummary: WorkoutSummaryData?

    // State restoration prompt
    @State private var pendingRestoredState: WorkoutState?
    @State private var showRestorePrompt: Bool = false

    var body: some View {
        TimerSelectionView(
            onNavigateToHistory: {
                navState = .history
            },
            onWorkoutComplete: { summary in
                pendingWorkoutSummary = summary
            },
            onStartWorkout: { config in
                navState = .activeWorkout(config, restoredState: nil)
            }
        )
        // Active workout full-screen cover
        .fullScreenCover(isPresented: Binding(
            get: {
                if case .activeWorkout = navState { return true }
                return false
            },
            set: { if !$0 { navState = .home } }
        )) {
            if case .activeWorkout(let config, let restoredState) = navState {
                TimerView(
                    configuration: config,
                    restoredState: restoredState,
                    onWorkoutStateChange: { _ in },
                    onFinish: { summary in
                        navState = .summary(summary)
                    }
                )
            }
        }
        // Summary full-screen cover
        .fullScreenCover(isPresented: Binding(
            get: {
                if case .summary = navState { return true }
                return false
            },
            set: { if !$0 { navState = .home } }
        )) {
            if case .summary(let summary) = navState {
                WorkoutSummaryView(
                    data: summary,
                    onDismiss: {
                        navState = .home
                    },
                    onRepeat: {
                        let config = summary.configuration
                        navState = .activeWorkout(config, restoredState: nil)
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
                },
                onRepeat: {
                    let config = summary.configuration
                    pendingWorkoutSummary = nil
                    navState = .activeWorkout(config, restoredState: nil)
                }
            )
        }
        // History full screen
        .fullScreenCover(isPresented: Binding(
            get: { navState == .history },
            set: { if !$0 { navState = .home } }
        )) {
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
        .alert("Resume Workout?", isPresented: $showRestorePrompt) {
            Button("Resume") {
                if let state = pendingRestoredState {
                    navState = .activeWorkout(state.configuration, restoredState: state)
                }
                pendingRestoredState = nil
            }
            Button("Discard", role: .destructive) {
                WorkoutStateManager.shared.clearState()
                pendingRestoredState = nil
            }
        } message: {
            if let state = pendingRestoredState {
                Text("You have an unfinished \(state.configuration.timerType.displayName) workout. Would you like to resume where you left off?")
            }
        }
    }

    private func checkForStateRestoration() {
        if let savedState = WorkoutStateManager.shared.loadState() {
            pendingRestoredState = savedState
            showRestorePrompt = true
        }
    }
}
