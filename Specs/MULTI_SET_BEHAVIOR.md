# Multi-Set Behavior Specification

**Date**: 2025-01-20
**Status**: Implemented

---

## Overview

Multi-set functionality allows users to perform multiple consecutive working periods (sets) separated by rest intervals. This specification defines the complete behavior for multi-set workouts across all timer types.

---

## Core Concepts

### Set
A **set** is a single working period. For example:
- AMRAP: One 10-minute AMRAP period
- For Time: One timed effort to complete work
- EMOM: One complete EMOM session with all intervals

### Rest Period
A **rest period** is the countdown timer between sets. Rest periods:
- Are configurable (e.g., 60 seconds, 120 seconds, etc.)
- Countdown from rest duration to 0:00
- Can be skipped by user
- Automatically start the next set when complete

### Workflow
```
Set 1 (Working) → Rest Period → Set 2 (Working) → Rest Period → Set 3 (Working) → Finished
```

---

## User Journey

### Single Set Workout (numSets = 1)
1. User configures timer (AMRAP, EMOM, or For Time)
2. User starts workout
3. **Button displays**: "Finish Workout" (always available)
4. User completes work and taps "Finish Workout"
5. Workout ends, summary shown

### Multi-Set Workout (numSets > 1)

#### Set 1-N (Not Final Set)
1. User is on Set 1 of 3
2. **Button displays**: "Complete Set" (green accent)
3. **Set indicator shows**: "Set 1 of 3"
4. User taps "Complete Set" when ready
5. Current set ends, elapsed time saved
6. Rest period begins automatically
7. **Button displays**: "Skip Rest" during rest countdown
8. Rest period ends (or user skips)
9. Next set starts automatically

#### Final Set (Set N)
1. User is on Set 3 of 3
2. **Button displays**: "Finish Workout" (accent color)
3. **Set indicator shows**: "Set 3 of 3"
4. User taps "Finish Workout"
5. Entire workout ends, summary shown with all sets

---

## Manual Set Completion

All timer types support **manual set completion**:

### For Time (No Time Cap)
- User taps "Complete Set" when work is done
- Timer stops, elapsed time recorded
- Rest period begins

### For Time (With Time Cap)
- **Auto-complete**: If time cap reached, set completes automatically
- **Manual**: User can tap "Complete Set" before cap reached
- Rest period begins after completion

### AMRAP (Always Has Duration)
- **Auto-complete**: When countdown reaches 0:00, set completes automatically
- **Manual**: User can tap "Complete Set" to end set early
- Rest period begins after completion

### EMOM (Always Has Duration)
- **Auto-complete**: When all intervals complete, set completes automatically
- **Manual**: User can tap "Complete Set" to end set early (useful if user can't complete work)
- Rest period begins after completion

---

## Button Behavior Specification

### Adaptive Button Strategy
The primary action button changes **label** and **behavior** based on context:

| State | Current Set | Button Label | Button Action | Button Color |
|-------|-------------|--------------|---------------|--------------|
| Idle | Any | "Start Workout" | Start first set | Green |
| Running | 1 to N-1 | "Complete Set" | End set, start rest | Green |
| Running | N (final) | "Finish Workout" | End entire workout | Accent (timer-specific) |
| Paused | Any | "Resume" | Resume current set | Green |
| Resting | Any | "Skip Rest" | Skip rest, start next set | Blue |

### Button Icons

| Context | Icon |
|---------|------|
| Start Workout | `play.fill` |
| Complete Set | `checkmark.circle.fill` |
| Finish Workout | `checkmark.circle.fill` |
| Resume | `play.fill` |
| Skip Rest | `forward.fill` |

---

## State Transitions

### Complete Set (Not Final Set)
```
State: .running
currentSet: 1 (of 3)
↓
User taps "Complete Set"
↓
TimerViewModel.completeSetTapped()
↓
TimerEngine.completeSet()
↓
- Accumulate elapsed time
- Save current set data
- Check: currentSet < numSets? → YES
↓
TimerEngine.startRest()
↓
State: .resting
- Start rest countdown
- Display: "Rest Period"
- Button: "Skip Rest"
↓
Rest completes (auto or skip)
↓
TimerEngine.start() (called automatically)
↓
State: .running
currentSet: 2 (of 3)
- Reset round counters
- Reset elapsed time for new set
```

### Complete Final Set
```
State: .running
currentSet: 3 (of 3)
↓
User taps "Finish Workout"
↓
TimerViewModel.completeSetTapped()
↓
TimerEngine.completeSet()
↓
- Accumulate elapsed time
- Save current set data
- Check: currentSet < numSets? → NO
↓
TimerEngine.finish()
↓
State: .finished
- Stop timer
- Emit "finish" event
- Save complete workout
- Show summary
```

---

## Round Tracking Per Set

### Behavior
- Rounds **reset to 0** at the start of each set
- Each set maintains its own round split times
- Round splits are saved per set in `allRoundSplits[][]`

### Example: 3 Sets of AMRAP
```
Set 1:
  Round 1: 1:23 (split)
  Round 2: 1:45 (split)
  Round 3: 2:01 (split)
  Total: 5:09

[REST: 60 seconds]

Set 2: (rounds reset to 0)
  Round 1: 1:28 (split)
  Round 2: 1:50 (split)
  Total: 3:18

[REST: 60 seconds]

Set 3: (rounds reset to 0)
  Round 1: 1:35 (split)
  Round 2: 1:55 (split)
  Round 3: 2:10 (split)
  Total: 5:40
```

---

## Visual Indicators

### Set Indicator Display
```
Single Set:
  (No set indicator shown)

Multi-Set (Not Final):
  📊 Set 1 of 3
  📊 Set 2 of 3

Multi-Set (Final):
  📊 Set 3 of 3
```

### Rest Period Display
```
Large Countdown:
  REST

  01:23

  [Skip Rest Button]
```

---

## API Changes

### TimerEngine.swift

#### New Method: `completeSet()`
```swift
public func completeSet() {
    // Accumulate any remaining time
    if state == .running, let startTime = startWallTime {
        accumulated += Date().timeIntervalSince(startTime)
    }

    stopDisplayLink()

    // Check if more sets remaining
    if shouldStartNextSet() {
        startRest() // Start rest period
    } else {
        finish() // End entire workout
    }
}
```

### TimerViewModel.swift

#### New Method: `completeSetTapped()`
```swift
func completeSetTapped() {
    guard state == .running else { return }
    engine.completeSet()
    // State changes handled by delegate callbacks
}
```

### TimerView.swift

#### Updated: Control Button Logic
```swift
private var finishButtonLabel: String {
    if state == .resting {
        return "Skip Rest"
    } else if state == .running {
        if currentSet < numSets {
            return "Complete Set"
        } else {
            return "Finish Workout"
        }
    }
    return "Finish"
}
```

---

## Audio/Haptic Feedback

### Set Completion
- **Audio**: `end.caf` (same as workout finish)
- **Haptic**: Success pattern
- **Event**: `"set_complete"`

### Rest Start
- **Audio**: `end.caf` (signals transition)
- **Haptic**: Success pattern
- **Event**: `"rest_start"` (existing)

### Rest Complete
- **Audio**: `start.caf` (signals new set)
- **Haptic**: Rigid pattern
- **Event**: `"set_start"` (new)

---

## Edge Cases

### 1. Pause During Set
- User can pause mid-set
- "Resume" button appears
- Resume continues the same set (does not start rest)

### 2. Pause During Rest
- **Not Allowed**: Rest cannot be paused
- Rest continues countdown
- User can skip rest at any time

### 3. App Backgrounding During Rest
- Rest countdown continues via background audio
- State is saved
- On return, rest may have completed (auto-start next set)

### 4. Completing Set with No Rounds
- Valid: User can complete a set without marking any rounds
- Set still counts as complete
- Elapsed time is still recorded

### 5. Skipping Rest on Final Set
- **Not Applicable**: No rest period after final set
- Button shows "Finish Workout" during final set

---

## Accessibility

### VoiceOver Announcements
- **Set Start**: "Set 2 of 3 starting"
- **Set Complete**: "Set 2 complete. Rest period starting."
- **Rest Complete**: "Rest complete. Set 3 starting."
- **Final Set**: "Final set. Set 3 of 3."

### Button Labels
- Dynamic accessibility labels match visible button text
- Example: "Complete Set 2 of 3" or "Finish Workout"

### Dynamic Type Support
- Set indicator font scales with Dynamic Type
- Button text scales appropriately

---

## Persistence

### Workout State Saved
```json
{
  "currentSet": 2,
  "state": "resting",
  "elapsedSeconds": 634.5,
  "allSetElapsed": [600.0, 634.5],
  "roundSplitsPerSet": [
    [/* Set 1 rounds */],
    [/* Set 2 rounds in progress */]
  ]
}
```

### Completed Workout
```json
{
  "totalDuration": 1920.5,
  "numSets": 3,
  "setTimes": [600.0, 634.5, 685.0],
  "roundSplitsPerSet": [
    [/* Set 1 rounds */],
    [/* Set 2 rounds */],
    [/* Set 3 rounds */]
  ]
}
```

---

## Testing Requirements

### Manual Testing Checklist

#### Multi-Set AMRAP (3 sets, 2 min each, 30s rest)
- [ ] Start Set 1, verify button shows "Complete Set"
- [ ] Tap "Complete Set" before time expires
- [ ] Verify rest period starts (30s countdown)
- [ ] Verify button shows "Skip Rest"
- [ ] Let rest complete automatically
- [ ] Verify Set 2 starts automatically
- [ ] Verify rounds reset to 0 for Set 2
- [ ] Complete Set 2 normally
- [ ] Skip rest period to Set 3
- [ ] Verify Set 3 button shows "Finish Workout"
- [ ] Complete workout, verify summary shows all 3 sets

#### Multi-Set For Time (2 sets, 5 min cap, 60s rest)
- [ ] Start Set 1, work for 3 minutes
- [ ] Tap "Complete Set" at 3:00
- [ ] Verify rest starts
- [ ] Complete rest, verify Set 2 starts
- [ ] Let time cap expire on Set 2
- [ ] Verify workout auto-completes

#### Multi-Set EMOM (2 sets, 5 intervals × 60s, 90s rest)
- [ ] Complete all 5 intervals in Set 1
- [ ] Verify auto-transition to rest
- [ ] Verify Set 2 starts after rest
- [ ] Manually tap "Complete Set" during Set 2 interval 3
- [ ] Verify early completion works

### Edge Case Testing
- [ ] Pause during set, resume, complete set
- [ ] Background app during rest, foreground after rest ends
- [ ] State restoration after force quit during rest
- [ ] Skip rest on Set 1, skip rest on Set 2
- [ ] Complete workout without marking any rounds

---

## Implementation Status

- [x] Specification documented
- [ ] TimerEngine.completeSet() implemented
- [ ] TimerViewModel.completeSetTapped() implemented
- [ ] TimerView adaptive button implemented
- [ ] Audio/haptic feedback added
- [ ] Accessibility labels updated
- [ ] Manual testing complete
- [ ] Documentation updated

---

**Version**: 1.0
**Last Updated**: 2025-01-20
**Status**: Ready for Implementation
