# Quick Start Confirmation Sheet Integration Plan

## Current State

**Files Involved:**
- `MainContainerView.swift` - Uses countdown toast (QuickStartCountdownToast)
- `MainContainerViewModel.swift` - Manages countdown timer logic
- `QuickStartConfirmationSheet.swift` - Fully implemented confirmation sheet (UNUSED)
- `QuickStartCountdownToast.swift` - Currently active countdown toast (TO BE REPLACED)

## Required Changes

### 1. Update MainContainerViewModel.swift

**Replace countdown logic with sheet presentation state:**

```swift
class MainContainerViewModel: ObservableObject, ConfigurationProvider {
    // MARK: - Published Properties
    
    @Published var navigationState: AppNavigationState = .home
    
    // CHANGE: Replace countdown state with sheet presentation state
    @Published var showQuickStartSheet = false
    @Published var quickStartConfig: TimerConfiguration?
    
    // REMOVE: These countdown-related properties
    // @Published var isCountingDown = false
    // @Published var countdownSeconds = 10
    // private var countdownTimer: AnyCancellable?
    // private var pendingConfig: TimerConfiguration?
    
    // MARK: - Quick Start
    
    func initiateQuickStart(for timerType: TimerType) {
        // Get smart default configuration
        let config = quickStartConfiguration(for: timerType)
        
        // Store config and show sheet
        quickStartConfig = config
        showQuickStartSheet = true
    }
    
    func confirmQuickStart() {
        guard let config = quickStartConfig else { return }
        
        // Navigate directly to active workout
        navigationState = .activeWorkout(config, restoredState: nil)
        
        // Reset sheet state
        showQuickStartSheet = false
        quickStartConfig = nil
    }
    
    func cancelQuickStart() {
        showQuickStartSheet = false
        quickStartConfig = nil
    }
    
    // REMOVE: handleCountdownTick() and completeQuickStart() methods
}
```

### 2. Update MainContainerView.swift

**Replace toast overlay with sheet presentation:**

```swift
struct MainContainerView: View {
    @StateObject private var viewModel = MainContainerViewModel()
    @State private var isWorkoutActive = false

    var body: some View {
        NavigationView {
            timerListView
                .navigationTitle("Workout Timer")
                .navigationBarTitleDisplayMode(.large)
            
            contentPane
        }
        // REMOVE: .overlay with QuickStartCountdownToast
        // REPLACE WITH: .sheet presentation
        .sheet(isPresented: $viewModel.showQuickStartSheet) {
            if let config = viewModel.quickStartConfig {
                QuickStartConfirmationSheet(
                    configuration: config,
                    onConfirm: {
                        viewModel.confirmQuickStart()
                        isWorkoutActive = true
                    },
                    onCancel: {
                        viewModel.cancelQuickStart()
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            checkForStateRestoration()
        }
    }
    
    // ... rest remains the same
}
```

## Benefits of This Change

1. **Clearer UX**: User explicitly confirms Quick Start instead of racing against countdown
2. **Better Accessibility**: Sheet provides more context and clearer action buttons
3. **Follows iOS Patterns**: Sheet presentation is more standard than toast overlays
4. **Simpler Logic**: Removes timer management complexity from ViewModel
5. **Better Control**: User can review settings before starting

## Testing Checklist

- [ ] Quick Start sheet appears when Quick Start button tapped
- [ ] Configuration details display correctly for each timer type
- [ ] "Start Workout" button transitions to active workout
- [ ] "Cancel" button dismisses sheet without starting workout
- [ ] Sheet drag-to-dismiss works and properly cancels
- [ ] VoiceOver announces configuration details clearly
- [ ] Dynamic Type scales properly at XXXL
- [ ] Hit targets meet 52pt minimum (currently 56pt for primary button)

## Files to Modify

1. `/Users/geoffreymacgillivray/Programs/Most Final WOD Timer/Sources/UI/ViewModels/MainContainerViewModel.swift`
2. `/Users/geoffreymacgillivray/Programs/Most Final WOD Timer/Sources/UI/Screens/MainContainerView.swift`

## Files to Deprecate (Optional)

- `/Users/geoffreymacgillivray/Programs/Most Final WOD Timer/Sources/UI/Components/QuickStartCountdownToast.swift`
  (Can be removed once sheet integration is confirmed working)
