# Round Timer Feature Specification

## Overview
Add automatic round time tracking to all timer types, replacing the existing rep/round counters with a unified round timer that records both round count and split times.

## User Story
**As an athlete exercising**, I want to track my round splits during a workout so that I can analyze my pacing and performance after the workout is complete.

## Functional Requirements

### FR-1: Round Counter Button
- **Replace** existing rep/round counter buttons entirely
- Button displays current round number and "Tap to Complete Round" label
- Button positioned below the main timer display
- Button disabled during rest periods
- Button disabled when timer is paused or finished

### FR-2: Round Time Tracking
- **First round**: Starts when workout starts (timer transitions to running state)
- **Subsequent rounds**: Start when previous round button is tapped
- **Last round**: Ends when workout is finished (user taps Done or timer completes)
- **Paused time**: Excluded from round times (only count active running time)
- **Rest time**: Excluded from round times

### FR-3: Multi-Set Behavior
- Round counts **reset** at the start of each new set
- Round 1 of Set 2 starts when Set 2 begins (after rest period ends)
- Each set has independent round tracking
- Round times stored with set association

### FR-4: Current Round Display
- Display **current round elapsed time** below the main timer
- Font size: **smaller than main timer** (suggested: 40% of timer font)
- Label: "Current Round" or "Round X Time"
- Updates every tick while timer is running
- Format: MM:SS (same as main timer)

### FR-5: Data Storage Schema

#### WorkoutSet Entity (existing - extend)
Add relationship to RoundSplit entities:
```swift
@NSManaged public var roundSplits: NSSet?
```

#### New Entity: RoundSplit
```
Entity: RoundSplit
Attributes:
- roundNumber: Int16 (1-based round number within the set)
- splitTime: Double (duration of this round in seconds)
- timestamp: Date (when round was completed)
- cumulativeTime: Double (total elapsed time at round completion)

Relationships:
- workoutSet: WorkoutSet (inverse: roundSplits)
```

#### Storage Rules
- Store round split when user taps round button
- Store final round split on workout completion
- Associate each round with its parent WorkoutSet
- Calculate split time = current elapsed - previous round cumulative time

### FR-6: Workout Summary Display
On workout completion, display:

**Summary Screen Updates:**
```
Workout Complete!
AMRAP - 20:00

Total Time: 20:00

Set 1 - 5 Rounds
  Round 1: 3:24
  Round 2: 3:42
  Round 3: 4:01
  Round 4: 4:18
  Round 5: 4:35

Set 2 - 4 Rounds  (if multi-set)
  Round 1: 3:56
  Round 2: 4:12
  Round 3: 4:28
  Round 4: 3:24

[Done Button]
```

### FR-7: Workout History Display
In WorkoutDetailView, show:
- Total rounds completed per set
- Expandable list of round splits per set
- Average round time per set
- Fastest/slowest round indicators

## Technical Implementation

### Phase 1: Data Model
1. Create RoundSplit Core Data entity
2. Add relationship to WorkoutSet
3. Create RoundSplit+CoreDataClass.swift
4. Create RoundSplit+CoreDataProperties.swift

### Phase 2: Timer Engine
1. Update TimerViewModel to track round splits
2. Add `completeRound()` method
3. Add `currentRoundElapsed` computed property
4. Track round start times per set
5. Exclude paused/rest time from calculations

### Phase 3: UI Components
1. Update TimerView round counter button
   - Replace existing rep/round counter
   - Show current round number
   - Show "Tap to Complete Round" label
   - Disable during pause/rest/finished
2. Add current round time display
   - Position below main timer
   - Responsive font size (iPad vs iPhone)
   - Update on every tick
3. Update WorkoutSummaryView
   - Display round splits per set
   - Show round count per set
   - Scrollable list for many rounds
4. Update WorkoutDetailView
   - Show round splits in history
   - Display round statistics

### Phase 4: Testing
1. Unit tests for round time calculations
2. UI tests for round button interaction
3. Test multi-set round resets
4. Test pause/resume round time exclusion
5. Test data persistence

## Edge Cases

### EC-1: Zero Rounds Completed
- If user never taps round button, store workout with 0 rounds
- Don't show rounds section in summary

### EC-2: Workout Finished Mid-Round
- If user finishes workout, save current round as final round
- Calculate final round time from last round tap to finish time

### EC-3: Single Round Workout
- If user completes workout with only 1 round button tap
- Show 2 rounds: Round 1 (start to tap), Round 2 (tap to finish)

### EC-4: Very Long Round Times
- Support rounds up to timer duration (e.g., 60 minute AMRAP)
- Display format: H:MM:SS for rounds >= 1 hour

### EC-5: Rapid Tapping
- No debounce - each tap counts as a new round
- Accept intentional rapid rounds (e.g., singles in weightlifting)

## UI/UX Specifications

### Round Counter Button Design
```
┌─────────────────────────────┐
│         Round 3             │  ← Large, bold round number
│    Tap to Complete Round    │  ← Instructional text
└─────────────────────────────┘
Color: Accent color for timer type
Size: Same width as timer controls
Hit Target: Minimum 52pt height (accessibility)
```

### Current Round Time Display
```
        00:45        ← Main Timer (96pt/192pt)

      Running        ← State indicator

     Current Round   ← Label (14pt)
        03:24        ← Current round time (38pt/76pt on iPad)
```

### Font Size Ratios
- **iPhone**: Main timer 96pt, Current round 38pt (40% ratio)
- **iPad**: Main timer 192pt, Current round 76pt (40% ratio)

## Acceptance Criteria

### AC-1: Round Counter Button
- [ ] Button appears below timer for all timer types
- [ ] Button shows current round number (starting at 1)
- [ ] Button disabled during rest periods
- [ ] Button disabled when paused
- [ ] Button disabled when finished

### AC-2: Round Time Tracking
- [ ] Tapping button increments round count
- [ ] First round starts from workout start
- [ ] Paused time excluded from round times
- [ ] Rest time excluded from round times
- [ ] Last round auto-completed on workout finish

### AC-3: Multi-Set Rounds
- [ ] Round count resets to 1 when new set starts
- [ ] Each set has independent round tracking
- [ ] Round times stored with set association

### AC-4: Current Round Display
- [ ] Current round time displayed below timer
- [ ] Updates every tick while running
- [ ] Font size 40% of main timer font
- [ ] Not shown during rest periods

### AC-5: Data Persistence
- [ ] Round splits saved to Core Data
- [ ] Associated with correct WorkoutSet
- [ ] Includes roundNumber, splitTime, timestamp, cumulativeTime
- [ ] Survives app restart

### AC-6: Summary Display
- [ ] Shows all rounds grouped by set
- [ ] Displays round times for each round
- [ ] Scrollable for many rounds
- [ ] Shows round count per set

### AC-7: History Display
- [ ] Round splits visible in workout detail view
- [ ] Round statistics calculated (avg, fastest, slowest)
- [ ] Expandable/collapsible per set

## Non-Functional Requirements

### Performance
- Round time calculations must not impact timer accuracy
- UI updates must maintain 60fps during round time display
- Core Data writes should be async (not block UI)

### Accessibility
- Round counter button minimum 52pt hit target
- VoiceOver announcement: "Round [X] completed, time [MM:SS]"
- Dynamic Type support for all text
- Color contrast ratio >= 7:1 for round time display

### Compatibility
- iOS 15+
- iPhone and iPad
- Portrait and landscape orientations
- Light and dark mode (dark mode only currently)

## Future Enhancements (Out of Scope)
- Manual round time editing
- Round time alerts (notify if round slower than target)
- Round time comparison across workouts
- Export round splits to CSV
- Audio cue on round completion
- Undo last round

---

**Document Version**: 1.0
**Created**: 2025-01-16
**Status**: Approved for Implementation
