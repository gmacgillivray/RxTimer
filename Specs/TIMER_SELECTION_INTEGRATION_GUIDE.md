# Timer Selection Integration Guide

## Overview

This guide shows how to integrate the new timer selection UI components into MainContainerView.

## Migration Summary

### Before (Sidebar Navigation)
- Sidebar with SidebarTimerRow components
- EmptyStateView in content pane
- QuickStartCountdownToast overlay
- History in sidebar list

### After (Card-Based Selection)
- TimerSelectionView as primary screen
- TimerTypeCard components for selection
- QuickStartConfirmationSheet modal
- History button in toolbar

## Component Replacement Map

| Old Component | New Component | Purpose |
|--------------|---------------|---------|
| `SidebarTimerRow` | `TimerTypeCard` | Display timer option |
| `EmptyStateView` | `TimerSelectionView` | Main selection screen |
| `QuickStartCountdownToast` | `QuickStartConfirmationSheet` | Quick Start confirmation |
| History in sidebar | History toolbar button | Access workout history |

## Integration Example

### Updated MainContainerView.swift

```swift
import SwiftUI

struct MainContainerView: View {
    @StateObject private var viewModel = MainContainerViewModel()
    @State private var isWorkoutActive = false

    var body: some View {
        NavigationView {
            // Content based on navigation state
            contentView
        }
        .preferredColorScheme(.dark)
        .onAppear {
            checkForStateRestoration()
        }
    }

    private func checkForStateRestoration() {
        if let savedState = WorkoutStateManager.shared.loadState() {
            viewModel.navigationState = .activeWorkout(
                savedState.configuration,
                restoredState: savedState
            )
            isWorkoutActive = true
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.navigationState {
        case .home:
            // NEW: Timer selection with cards
            TimerSelectionView(
                onSelectTimer: { timerType in
                    viewModel.navigationState = .configuration(timerType)
                },
                onQuickStart: { configuration in
                    // Start workout immediately
                    viewModel.navigationState = .activeWorkout(
                        configuration,
                        restoredState: nil
                    )
                    isWorkoutActive = true
                },
                onNavigateToHistory: {
                    viewModel.navigationState = .history
                }
            )

        case .configuration(let timerType):
            InlineConfigureTimerView(
                timerType: timerType,
                onStart: { config in
                    viewModel.saveConfiguration(config)
                    viewModel.navigationState = .activeWorkout(
                        config,
                        restoredState: nil
                    )
                    isWorkoutActive = true
                },
                onCancel: {
                    viewModel.navigationState = .home
                }
            )

        case .activeWorkout(let config, let restoredState):
            TimerView(
                configuration: config,
                restoredState: restoredState,
                onWorkoutStateChange: { isActive in
                    isWorkoutActive = isActive
                },
                onFinish: { summaryData in
                    viewModel.navigationState = .summary(summaryData)
                    isWorkoutActive = false
                }
            )

        case .summary(let data):
            WorkoutSummaryView(
                data: data,
                onDismiss: {
                    viewModel.navigationState = .home
                }
            )

        case .history:
            WorkoutHistoryView(
                onSelectWorkout: { workout in
                    viewModel.navigationState = .historyDetail(workout)
                }
            )

        case .historyDetail(let workout):
            WorkoutDetailView(
                workout: workout,
                onDismiss: {
                    viewModel.navigationState = .history
                }
            )
        }
    }
}
```

### Simplified MainContainerViewModel.swift

```swift
import Foundation
import Combine
import SwiftUI

class MainContainerViewModel: ObservableObject, ConfigurationProvider {
    @Published var navigationState: AppNavigationState = .home

    // Quick Start countdown logic REMOVED
    // (Now handled by QuickStartConfirmationSheet)

    // Configuration management remains
    // (Used by TimerSelectionView to get last used configs)
}
```

## Key Changes

### 1. Removed Countdown Timer Logic

**Before**:
```swift
@Published var isCountingDown = false
@Published var countdownSeconds = 10
private var countdownTimer: AnyCancellable?

func initiateQuickStart(for timerType: TimerType) {
    let config = quickStartConfiguration(for: timerType)
    pendingConfig = config
    countdownSeconds = 10
    isCountingDown = true

    countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
            self?.handleCountdownTick()
        }
}
```

**After**:
Quick Start now shows confirmation sheet immediately - no countdown needed.

### 2. Direct Quick Start Flow

**Before**:
1. User taps Quick Start
2. Toast appears with 10s countdown
3. User can cancel or wait
4. After 10s, workout starts

**After**:
1. User taps Quick Start
2. Confirmation sheet appears immediately
3. User reviews and taps "Start Workout"
4. Workout starts instantly

### 3. Navigation Structure

**Before**:
- Sidebar always visible (iPad-style)
- Content pane changes based on state
- History in sidebar list

**After**:
- Timer selection is full-screen primary view
- Navigation happens via state changes
- History accessed via toolbar button

## Testing Migration

### Unit Tests to Update

1. **MainContainerViewModelTests**:
   - Remove countdown timer tests
   - Update Quick Start tests to expect immediate navigation
   - Remove `isCountingDown` state tests

2. **UI Tests to Update**:
   - Update timer selection flow to find cards instead of sidebar rows
   - Add Quick Start confirmation sheet tests
   - Update history access tests (toolbar button instead of sidebar)

### Example Test Updates

**Before**:
```swift
func testQuickStartInitiatesCountdown() {
    viewModel.initiateQuickStart(for: .amrap)

    XCTAssertTrue(viewModel.isCountingDown)
    XCTAssertEqual(viewModel.countdownSeconds, 10)
}
```

**After**:
```swift
// Test in TimerSelectionViewModelTests instead
func testQuickStartShowsConfirmation() {
    viewModel.initiateQuickStart(for: .amrap)

    XCTAssertTrue(viewModel.showingQuickStartConfirmation)
    XCTAssertNotNil(viewModel.pendingQuickStartConfig)
    XCTAssertEqual(viewModel.pendingQuickStartConfig?.timerType, .amrap)
}
```

## Color Assets Needed

Add these to `Assets.xcassets`:

### CardBackground.colorset
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.15",
          "green" : "0.15",
          "red" : "0.15"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### SecondaryBackground.colorset
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.10",
          "green" : "0.10",
          "red" : "0.10"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Note: `AccentColor` should already exist in project.

## Incremental Migration Path

If you need to migrate gradually:

### Phase 1: Add New Components (No Breaking Changes)
1. Add `TimerTypeCard.swift`
2. Add `QuickStartConfirmationSheet.swift`
3. Add `TimerSelectionView.swift`
4. Preview and test in Xcode previews

### Phase 2: Wire Up Navigation (Test in Isolation)
1. Create new `TimerSelectionViewModel`
2. Test Quick Start confirmation flow
3. Test card navigation flow

### Phase 3: Integrate into MainContainerView
1. Replace `.home` case with `TimerSelectionView`
2. Update `onQuickStart` callback to start immediately
3. Remove countdown toast overlay

### Phase 4: Cleanup
1. Remove `SidebarTimerRow.swift` (if unused elsewhere)
2. Remove `EmptyStateView` (defined in MainContainerView)
3. Remove `QuickStartCountdownToast.swift`
4. Remove countdown logic from `MainContainerViewModel`

### Phase 5: Update Tests
1. Update MainContainerView UI tests
2. Add TimerSelectionView tests
3. Add QuickStartConfirmationSheet tests

## Accessibility Testing Script

### VoiceOver Navigation Test
1. Enable VoiceOver (Cmd+F5 in Simulator)
2. Swipe right from top:
   - Should hear: "RxTimer, heading"
   - Next: "Workout History, button"
   - Next: "Select Timer, heading"
   - Next: Each timer card in order
   - Next: Quick Start button for each card
3. Double-tap Quick Start button:
   - Should hear: Sheet presentation sound
   - Navigation should land on "Cancel" button
4. Swipe through sheet:
   - Should hear all configuration details
   - Should hear "Start Workout, button"

### Dynamic Type Test
1. Settings > Accessibility > Display & Text Size > Larger Text
2. Set to XXXL
3. Launch app
4. Verify:
   - Text scales appropriately
   - No text truncation
   - Buttons remain tappable
   - Card layout doesn't break

### Color Contrast Test
1. Enable Color Blind Filters:
   - Settings > Accessibility > Display > Color Filters
   - Test Protanopia, Deuteranopia, Tritanopia
2. Verify:
   - Timer type colors remain distinguishable
   - Text remains readable
   - Quick Start buttons stand out

## Common Integration Issues

### Issue 1: Sheet Not Presenting
**Symptom**: Tapping Quick Start does nothing

**Check**:
- Is `showingQuickStartConfirmation` properly bound to `.sheet(isPresented:)`?
- Is `pendingQuickStartConfig` set before showing sheet?
- Is sheet modifier on correct view in hierarchy?

**Fix**:
```swift
.sheet(isPresented: $viewModel.showingQuickStartConfirmation) {
    if let config = viewModel.pendingQuickStartConfig {
        QuickStartConfirmationSheet(...)
    }
}
```

### Issue 2: Cards Not Appearing
**Symptom**: Empty screen or layout issues

**Check**:
- Are color assets added to Assets.xcassets?
- Is `TimerConfiguration` available for each timer type?
- Is preview working in Xcode?

**Fix**: Ensure all required color assets exist, use fallbacks:
```swift
.fill(Color("CardBackground") ?? Color(white: 0.15))
```

### Issue 3: Navigation Not Working
**Symptom**: Tapping card doesn't navigate

**Check**:
- Is `onSelectTimer` callback properly connected?
- Is `navigationState` updating in view model?
- Is `contentView` switch statement handling `.configuration` case?

**Fix**: Add debug prints to trace navigation flow:
```swift
onSelectTimer: { timerType in
    print("Selected timer: \(timerType)")
    viewModel.navigationState = .configuration(timerType)
}
```

### Issue 4: Configuration Summary Shows "Not configured"
**Symptom**: "LAST USED" section shows incorrect data

**Check**:
- Is `quickStartConfiguration(for:)` returning valid config?
- Are UserDefaults keys correct?
- Has user ever configured this timer?

**Fix**: Verify defaults are correct:
```swift
func configuration(for timerType: TimerType) -> TimerConfiguration {
    // Try to load from UserDefaults
    let key = "QuickStart.LastConfig.\(timerType.rawValue)"
    if let data = UserDefaults.standard.data(forKey: key),
       let config = try? JSONDecoder().decode(TimerConfiguration.self, from: data) {
        return config
    }

    // Always fall back to default
    return TimerConfiguration.defaultQuickStart(for: timerType)
}
```

## Performance Considerations

### Card Rendering
- Each card is relatively simple - no performance concerns
- Shadow and gradient use native Metal rendering
- Profile with Instruments if >3 timer types added

### Sheet Presentation
- Standard SwiftUI sheet - optimized by system
- Medium detent reduces rendering overhead
- Configuration view only rendered when sheet appears

### Recent Workout Query
- Should load on view appear, cache in ViewModel
- Don't query on every render
- Consider background fetch if history is large

Example:
```swift
class TimerSelectionViewModel: ObservableObject {
    @Published var mostRecentWorkout: WorkoutSummaryData?

    init(...) {
        // ...
        loadRecentWorkout()
    }

    private func loadRecentWorkout() {
        // Load in background
        DispatchQueue.global(qos: .userInitiated).async {
            let workout = WorkoutHistoryManager.shared.mostRecent()

            DispatchQueue.main.async {
                self.mostRecentWorkout = workout
            }
        }
    }
}
```

## Rollback Plan

If new UI causes issues, quick rollback:

1. Revert MainContainerView to sidebar version
2. Revert MainContainerViewModel countdown logic
3. Keep new components in codebase (no breaking changes)
4. Add feature flag to toggle between old/new UI

```swift
struct MainContainerView: View {
    @AppStorage("useNewTimerSelection") private var useNewUI = false

    var body: some View {
        if useNewUI {
            // New card-based UI
            TimerSelectionView(...)
        } else {
            // Old sidebar UI
            timerListView
        }
    }
}
```

This allows A/B testing and safe deployment.

## Summary

New components:
- `TimerTypeCard.swift` - Card component for timer selection
- `QuickStartConfirmationSheet.swift` - Confirmation modal for Quick Start
- `TimerSelectionView.swift` - Main selection screen

Modified files:
- `MainContainerView.swift` - Use TimerSelectionView for `.home` case
- `MainContainerViewModel.swift` - Remove countdown timer logic

Removed components:
- `QuickStartCountdownToast.swift` - Replaced by confirmation sheet
- Countdown timer logic - No longer needed

The migration is straightforward and non-breaking. New components can be added, tested, and integrated incrementally without disrupting existing functionality.
