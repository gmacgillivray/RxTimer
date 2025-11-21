# Timer Idle State Display Requirements

## Date: 2025-01-18

## Problem Statement

**Current Behavior**: When a user configures an AMRAP workout and taps "Start Workout", the timer screen shows "00:00" in the idle state. Only after tapping the "Start" button (play button) does the timer display the configured duration (e.g., "10:00").

**Desired Behavior**: When a user enters the timer screen (idle state), they should immediately see the configured duration for countdown timers (AMRAP), not "00:00".

## User Story

```
As a user configuring an AMRAP workout,
When I tap "Start Workout" and see the timer screen,
I want to immediately see the configured duration (e.g., "10:00")
So that I can verify my configuration before starting the workout
```

## Current User Flow (Problematic)

```
1. User configures AMRAP for 10 minutes
2. User taps "Start Workout"
   → Navigate to TimerView
   → Timer state: .idle
   → Display shows: "00:00" ❌ (Unexpected)
3. User taps "Start" button
   → Timer state: .running
   → Display shows: "10:00" → "09:59" → ... ✅ (Expected)
```

## Desired User Flow

```
1. User configures AMRAP for 10 minutes
2. User taps "Start Workout"
   → Navigate to TimerView
   → Timer state: .idle
   → Display shows: "10:00" ✅ (Expected - ready to count down)
3. User taps "Start" button
   → Timer state: .running
   → Display shows: "10:00" → "09:59" → ... ✅ (Expected - counting down)
```

## Requirements

### Functional Requirements

#### FR1: AMRAP Idle State Display
- **Requirement**: AMRAP timers in idle state SHALL display the configured duration
- **Example**: 10-minute AMRAP shows "10:00" before starting
- **Rationale**: Users need to verify their configuration matches their intent

#### FR2: Countdown Timer Initial Display
- **Requirement**: Any timer that counts down SHALL show its starting value in idle state
- **Timer Types**: AMRAP (current), future countdown variants
- **Rationale**: Countdown timers have a known starting point

#### FR3: Count-Up Timer Initial Display
- **Requirement**: Timers that count up MAY show "00:00" or configured cap in idle state
- **Timer Types**: For Time, EMOM
- **Rationale**: Count-up timers start from zero (TBD based on clarifying questions)

#### FR4: State Consistency
- **Requirement**: Idle state display SHALL be consistent with the value shown at the moment "Start" is pressed
- **Example**: If idle shows "10:00", pressing Start should begin from "10:00" (not jump to different value)
- **Rationale**: Prevents user confusion and maintains trust in the interface

#### FR5: Secondary Displays in Idle
- **Requirement**: Secondary timers (elapsed, round) SHALL be hidden in idle state
- **Rationale**: These timers only make sense during active workout
- **Status**: Currently implemented correctly

### Non-Functional Requirements

#### NFR1: Immediate Display
- **Requirement**: Configured time SHALL be visible within 100ms of view appearing
- **Rationale**: User should not see "00:00" flash before correct value appears

#### NFR2: Accessibility
- **Requirement**: VoiceOver SHALL announce the configured duration when view appears in idle state
- **Example**: "AMRAP timer configured for 10 minutes. Time remaining: 10 minutes. Tap Start to begin."
- **Rationale**: Screen reader users need same information as sighted users

#### NFR3: State Restoration
- **Requirement**: If app restarts in idle state (unlikely edge case), SHALL restore configured duration display
- **Rationale**: Consistency across all app lifecycle scenarios

## Display Specifications by Timer Type

### AMRAP (Priority - Current Issue)

| State | Main Display | Elapsed Display | Round Display | State Indicator |
|-------|--------------|-----------------|---------------|-----------------|
| **Idle** | Configured duration (e.g., "10:00") | Hidden | Hidden | Hidden or "Ready" |
| **Running** | Remaining time (countdown) | Elapsed time (countup) | Current round | "Running" |
| **Paused** | Remaining time (frozen) | Hidden | Hidden | "Paused" |
| **Finished** | "00:00" | Hidden | Hidden | "Finished" |

### For Time (TBD - Clarifying Questions Needed)

**Option A**: Show time cap if configured, otherwise "00:00"
**Option B**: Always show "00:00" (current behavior)

| State | Main Display | Round Display | State Indicator |
|-------|--------------|---------------|-----------------|
| **Idle** | TBD | Hidden | TBD |
| **Running** | Elapsed time (countup) | Current round | "Running" |
| **Paused** | Elapsed time (frozen) | Hidden | "Paused" |
| **Finished** | Final time | Hidden | "Finished" |

### EMOM (TBD - Clarifying Questions Needed)

**Option A**: Show total duration (e.g., "10:00" for 10 intervals × 60s)
**Option B**: Show "00:00"
**Option C**: Show first interval duration (e.g., "01:00")

| State | Main Display | Interval Display | State Indicator |
|-------|--------------|------------------|-----------------|
| **Idle** | TBD | TBD | TBD |
| **Running** | Total elapsed | Current interval | "Running" |
| **Paused** | Total elapsed (frozen) | Interval (frozen) | "Paused" |
| **Finished** | Total duration | "00:00" | "Finished" |

## Technical Context

### Current Implementation Issue

**File**: `Sources/UI/ViewModels/TimerViewModel.swift`

```swift
// Initialization (lines 54-87)
init(configuration: TimerConfiguration, restoredState: WorkoutState? = nil) {
    // ... configuration setup ...

    if let restored = restoredState {
        // Handles restored state correctly
        let elapsed = restored.elapsedSeconds
        if configuration.timerType == .amrap, let total = configuration.totalDurationSeconds {
            let remaining = Double(total) - elapsed
            self.timeText = formatTime(max(0, remaining))
            self.elapsedTimeText = formatTime(elapsed)
        } else {
            self.timeText = formatTime(elapsed)
        }
    } else {
        // NEW WORKOUT - NO INITIALIZATION OF timeText ❌
        self.workoutState = WorkoutState(configuration: configuration)
        self.currentSet = 1
        // timeText remains "00:00" (default value from property declaration)
    }
}
```

**Issue**: For new workouts (not restored), `timeText` is never initialized, so it uses the default value "00:00".

### Timer Display Updates

**File**: `Sources/UI/ViewModels/TimerViewModel.swift`

```swift
// timerDidTick only called when state is .running or .resting
func timerDidTick(elapsed: TimeInterval, remaining: TimeInterval?) {
    if state == .resting {
        // ... rest handling ...
    } else if state == .running {
        // ... running handling ...
        if timerConfiguration.timerType == .amrap {
            if let remaining = remaining {
                timeText = formatTime(max(0, remaining))
            }
            elapsedTimeText = formatTime(elapsed)
        }
    }
    // No handling for .idle state ❌
}
```

**Issue**: `timerDidTick` is only called during `.running` or `.resting` states. The `.idle` state never triggers a display update.

## Root Cause Analysis

### Why Does It Show "00:00" in Idle?

1. **Initialization**: `timeText` property defaults to "00:00"
2. **New Workout Path**: `init()` doesn't set `timeText` for new (non-restored) workouts
3. **No Idle Updates**: `timerDidTick()` is never called in `.idle` state
4. **First Display**: View shows default "00:00" until timer starts running

### Why Does It Work After Pressing Start?

1. **State Change**: `.idle` → `.running`
2. **Engine Starts**: `TimerEngine.start()` begins calling delegate methods
3. **First Tick**: `timerDidTick()` called with `elapsed = 0`, `remaining = 600` (for 10 min)
4. **Display Update**: `timeText = formatTime(600)` → "10:00" appears

### Sequence Diagram

```
User → Configure Screen → TimerView → ViewModel → Display
  |                           |            |           |
  | Select AMRAP 10 min       |            |           |
  |-------------------------->|            |           |
  |                           |            |           |
  | Tap "Start Workout"       |            |           |
  |-------------------------->|            |           |
  |                           | init()     |           |
  |                           |----------->|           |
  |                           |            | timeText defaults to "00:00"
  |                           |            |---------->| Shows "00:00" ❌
  |                           |            |           |
  | Tap "Start" button        |            |           |
  |-------------------------->|            |           |
  |                           | startTapped() |        |
  |                           |----------->|           |
  |                           |            | state = .running
  |                           |            | engine.start()
  |                           |            | timerDidTick() called
  |                           |            | timeText = "10:00"
  |                           |            |---------->| Shows "10:00" ✅
```

## Success Criteria

### Must Have
1. ✅ AMRAP timers show configured duration in idle state
2. ✅ Display updates within 100ms of view appearing
3. ✅ No visible "00:00" flash before correct value
4. ✅ Pressing "Start" maintains displayed value (no jump)
5. ✅ VoiceOver announces correct configured duration

### Should Have
1. ✅ For Time timers show appropriate idle value (per decision)
2. ✅ EMOM timers show appropriate idle value (per decision)
3. ✅ Consistent behavior across all timer types
4. ✅ State restoration maintains idle display

### Could Have
1. ✅ Animated transition from idle to running (future enhancement)
2. ✅ Visual "ready" indicator in idle state
3. ✅ Preview of first interval/round in idle

## Related Issues

### State Restoration
- Currently works correctly for paused state
- Restored workouts show correct time immediately
- Only affects NEW workouts entering idle state

### Multi-Set Workouts
- Same issue likely affects sets 2+ if they start in idle
- Should show configured duration for each set
- Rest periods correctly show countdown (working)

### Navigation
- Issue appears when navigating FROM configuration TO timer
- Does not affect navigating FROM summary TO timer (doesn't re-enter idle)

## Open Questions (To Be Answered)

See next section for clarifying questions.

---

*Requirements documented: 2025-01-18*
*Status: DRAFT - Awaiting clarification on For Time and EMOM behavior*
