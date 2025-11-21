# Navigation and Workflow Specification

## Overview
This document specifies the navigation flow and user workflow throughout the WorkoutTimer application.

## Navigation Flow

### Workout Flow (All Timer Types: For Time, AMRAP, EMOM)

```
Home Screen (Timer Selection)
    ↓ (User selects timer type)
Timer Configuration Screen
    ↓ (User taps "Start Workout")
Timer View (Active Workout)
    ↓ (User taps "Finish" or timer completes)
Workout Summary Screen
    ↓ (User taps "Done")
Home Screen (Timer Selection)
```

## Screen Behaviors

### 1. Home Screen
- **Purpose**: Timer type selection (For Time, AMRAP, EMOM)
- **Navigation**: Tap timer → Navigate to configuration

### 2. Timer Configuration Screen
- **Purpose**: Set timer parameters (duration, intervals, sets, rest)
- **Navigation**:
  - Back button → Return to home
  - "Start Workout" → Navigate to timer view

### 3. Timer View (Active Workout)
- **Purpose**: Display running timer and workout controls
- **Features**:
  - Main timer display
  - Current round time display
  - Round counter button
  - Start/Pause/Resume buttons
  - Finish button
  - Done button (top-left, disabled during idle)
- **Navigation**:
  - "Done" (top-left) → Finish workout early, navigate to summary
  - "Finish" (bottom) → Complete workout, navigate to summary
  - Automatic navigation to summary when timer reaches completion

### 4. Workout Summary Screen
- **Purpose**: Display workout results immediately after completion
- **Display Format**:
  - Success icon (checkmark for completed, warning for incomplete)
  - "Workout Complete!" or "Workout Saved" title
  - Timer type name
  - Total duration (large, gradient text)
  - Round splits (if any rounds were tracked)
  - "Done" button
- **Navigation**:
  - **"Done" button** → Dismiss summary, return to Home Screen
  - **NO back button** - User must use Done button
  - Summary disappears when Done is tapped

### 5. Workout History Detail Screen
- **Purpose**: View past workout details from history
- **Display Format**: Same visual format as Workout Summary Screen
- **Navigation**:
  - "Done" button → Return to History list
  - Back button hidden

## Navigation Implementation

### Inline Navigation
- Workout summary is **NOT a modal/sheet overlay**
- Summary is part of the navigation stack
- Provides consistent experience on iPhone and iPad
- **iPhone**: Summary fills entire screen
- **iPad**: Summary displays in right content area (sidebar remains visible)

### Dismissal Behavior
When user taps "Done" on Workout Summary:
1. **WorkoutSummaryView**: Calls `onDismiss()` callback (no `dismiss()` call)
2. **TimerView**: `onDismiss` callback calls `onFinish()` (doesn't reset `isNavigatingToSummary`)
3. **InlineConfigureTimerView**: `onFinish` callback calls `onWorkoutComplete()` (doesn't reset `isStartingWorkout`)
4. **MainContainerView**: `onWorkoutComplete` callback resets state:
   - `isWorkoutActive = false`
   - **`selectedTimerType = nil`** ← Triggers home screen display
5. **SwiftUI Re-render**: `selectedTimerType == nil` makes contentPane show EmptyStateView
6. All navigation-related views are removed from memory as contentPane rebuilds
7. NavigationLink states reset via `.onChange` handlers when needed for next workout

### State Management
MainContainerView uses state-based view selection:
- `selectedTimerType: TimerType?` - Controls which timer is selected (nil = home screen)
- `activeConfiguration: TimerConfiguration?` - Only used for state restoration from background
- `isWorkoutActive: Bool` - Tracks if a workout is currently running (disables sidebar)
- `restoredWorkoutState: WorkoutState?` - Holds restored state from background

**Navigation Architecture**:
1. **Sidebar buttons** set `selectedTimerType` state (no NavigationLinks in sidebar)
2. **contentPane** shows views based on `selectedTimerType`:
   - When `selectedTimerType == nil` → Show EmptyStateView (home screen)
   - When `selectedTimerType != nil` → Show InlineConfigureTimerView
   - Exception: When restoring from background, show TimerView directly
3. **Child views** use NavigationLinks for push/pop navigation:
   - InlineConfigureTimerView has NavigationLink to TimerView
   - TimerView has NavigationLink to WorkoutSummaryView
4. **State reset** (`selectedTimerType = nil`) triggers return to home screen

**NavigationLink State Management**:
- InlineConfigureTimerView has `isStartingWorkout` state controlling NavigationLink to TimerView
- TimerView has `isNavigatingToSummary` state controlling NavigationLink to WorkoutSummaryView
- **Critical**: These states are NOT reset in callbacks during dismissal flow
- NavigationLink states remain active until parent view rebuilds via `selectedTimerType = nil`
- `.onChange` handlers reset navigation states when parent state changes (for next workout)
- This allows summary to remain visible until user taps Done, then entire view hierarchy rebuilds

## User Experience Goals

### Clarity
- Clear visual hierarchy on each screen
- Obvious next actions at each step
- Consistent button placement and styling

### Efficiency
- Minimal taps to start workout
- Quick access to finish/pause controls
- Immediate summary display after completion

### Consistency
- Summary format matches history detail format
- Same visual language throughout app
- Predictable navigation patterns

## Accessibility

### Navigation Accessibility
- All navigation buttons have clear accessibility labels
- VoiceOver announces screen transitions
- Back navigation available via gesture and button
- Done button: 60pt minimum height (exceeds 52pt requirement)

### Labels
- Timer Configuration: "Start Workout"
- During Workout: "Finish" / "Done" (top-left)
- Workout Summary: "Finish and return to home"
- History Detail: "Return to history"

## Testing Requirements

### Navigation Tests
- [ ] Verify forward navigation through all screens
- [ ] Verify Done button dismisses summary and returns to home
- [ ] Verify no duplicate screens in navigation stack
- [ ] Verify iPad sidebar remains visible during navigation
- [ ] Verify back gesture works where appropriate
- [ ] Verify navigation with VoiceOver enabled

### Edge Cases
- [ ] Rapid tapping of navigation buttons
- [ ] Navigation during timer state transitions
- [ ] App backgrounding during navigation
- [ ] Memory cleanup when navigation stack pops

## Platform-Specific Behavior

### iPhone
- Summary fills full screen
- Sidebar hidden (compact size class)
- Standard navigation stack

### iPad
- Summary displays in right content area
- Sidebar remains visible (regular size class)
- Split view navigation

## Version History
- **v1.0** (2025-01-17): Initial specification
  - Defined complete navigation flow
  - Documented dismissal behavior
  - Specified summary screen format
  - Added accessibility requirements

- **v1.1** (2025-01-17): Architecture simplification
  - Fixed "Done button does nothing" issue
  - Unified navigation under state-based system
  - Removed NavigationLinks from sidebar (TimerNavigationRow)
  - Sidebar buttons now set `selectedTimerType` state
  - contentPane responds to state changes
  - Clarified NavigationLink state management
  - Updated dismissal behavior documentation
