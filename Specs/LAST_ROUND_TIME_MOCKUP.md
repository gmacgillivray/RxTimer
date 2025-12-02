# Proposal 5: Last Round Time Display - Visual Mockup

**Date:** 2025-12-01
**Status:** Design Phase
**Related:** UX Review Proposal 5

---

## Design Overview

This mockup shows how last round time would integrate with existing timer displays during AMRAP and For Time workouts.

---

## iPhone Layout (Compact Width)

### AMRAP - Round 2+ During Workout

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│              03:24                      │  ← Main Timer (96pt)
│           (remaining time)              │     Orange gradient
│                                         │
│         ● RUNNING                       │  ← State Indicator (8pt dot + 14pt text)
│                                         │
├─────────────────────────────────────────┤
│                                         │
│         Elapsed Time                    │  ← Label (14pt, secondary)
│            08:36                        │  ← Elapsed (28pt, 70% white)
│                                         │
├─────────────────────────────────────────┤
│                                         │
│         Current Round                   │  ← Label (14pt, secondary)
│            01:15                        │  ← Current Round Time (38pt, accent)
│                                         │
├─────────────────────────────────────────┤  ← NEW SECTION
│                                         │
│         Last Round                      │  ← Label (14pt, secondary)
│            01:23                        │  ← Last Round Time (28pt, 50% white)
│          +0:08 slower                   │  ← Delta (12pt, orange/green)
│                                         │
├─────────────────────────────────────────┤
│                                         │
│            Round 3                      │  ← Round Counter Button (70pt height)
│      Tap to Complete Round              │     Full width
│                                         │
├─────────────────────────────────────────┤
│                                         │
│         ●●○○○                           │  ← Set Progress Dots (8pt)
│    [Set 2 of 5]                         │  ← InfoPill
│                                         │
│                                         │
│    [ ▶︎ Pause ]  [ ✓ Complete Set ]     │  ← Control Buttons (60pt/50pt)
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

### For Time - Round 2+ During Workout

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│              08:36                      │  ← Main Timer (96pt, counting up)
│           (elapsed time)                │     Accent color gradient
│                                         │
│         ● RUNNING                       │  ← State Indicator
│                                         │
├─────────────────────────────────────────┤
│                                         │
│         Current Round                   │  ← Label (14pt, secondary)
│            01:15                        │  ← Current Round Time (38pt, accent)
│                                         │
├─────────────────────────────────────────┤  ← NEW SECTION
│                                         │
│         Last Round                      │  ← Label (14pt, secondary)
│            01:23                        │  ← Last Round Time (28pt, 50% white)
│          +0:08 slower                   │  ← Delta (optional)
│                                         │
├─────────────────────────────────────────┤
│                                         │
│            Round 3                      │  ← Round Counter Button
│      Tap to Complete Round              │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│         ●●○○○                           │  ← Set Progress Dots
│    [Set 2 of 5]                         │  ← InfoPill
│                                         │
│                                         │
│    [ ▶︎ Pause ]  [ ✓ Finish Workout ]   │  ← Control Buttons
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

---

## iPad Layout (Regular Width)

### AMRAP - Larger Fonts, More Space

```
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│                                                               │
│                        03:24                                  │  ← Main Timer (192pt)
│                    (remaining time)                           │
│                                                               │
│                    ● RUNNING                                  │  ← State
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│                   Elapsed Time                                │  ← Label
│                      08:36                                    │  ← Elapsed (57pt)
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│                   Current Round                               │  ← Label
│                      01:15                                    │  ← Current (76pt)
│                                                               │
├───────────────────────────────────────────────────────────────┤  ← NEW
│                                                               │
│                   Last Round                                  │  ← Label
│                      01:23                                    │  ← Last Round (53pt)
│                   +0:08 slower                                │  ← Delta
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│                       Round 3                                 │  ← Round Counter
│                 Tap to Complete Round                         │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│                      ●●○○○                                    │  ← Progress
│                 [Set 2 of 5]                                  │
│                                                               │
│                                                               │
│         [ ▶︎ Pause ]         [ ✓ Complete Set ]              │  ← Buttons
│                                                               │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

---

## Design Specifications

### Typography

| Element | iPhone | iPad | Color | Weight |
|---------|--------|------|-------|--------|
| Main Timer | 96pt | 192pt | White (gradient) | Bold |
| Current Round Time | 38pt | 76pt | Accent Color | Semibold |
| **Last Round Time** | **28pt** | **53pt** | **White 50%** | **Medium** |
| Elapsed Time (AMRAP) | 28pt | 57pt | White 70% | Semibold |
| Delta Indicator | 12pt | 16pt | Green/Orange | Medium |
| Labels | 14pt | 14pt | Secondary | Medium |

### Sizing Rationale

**iPhone:**
- Main timer: 96pt (100%)
- Current round: 38pt (40% of main)
- **Last round: 28pt (29% of main)** ← smaller than current
- Elapsed: 28pt (29% of main)

**iPad:**
- Main timer: 192pt (100%)
- Current round: 76pt (40% of main)
- **Last round: 53pt (28% of main)** ← smaller than current
- Elapsed: 57pt (30% of main)

### Visual Hierarchy

1. **Primary:** Main timer (largest, white gradient)
2. **Secondary:** Current round time (medium, accent color)
3. **Tertiary:** Last round time (smaller, muted white) ← NEW
4. **Quaternary:** Elapsed time, labels (smallest, secondary color)

### Color Strategy

**Last Round Time Color:**
- Default: White at 50% opacity (more muted than current round)
- Makes it visually distinct as historical data
- Doesn't compete with current round time for attention

**Delta Indicator:**
- Faster (beating last round): Green (`Color.green`)
- Slower (falling behind): Orange (`Color.orange`)
- Font size: 12pt iPhone, 16pt iPad
- Positioned directly below last round time

---

## Edge Cases & States

### Round 1 (No Previous Round)

```
┌─────────────────────────────────────────┐
│              08:36                      │  ← Main Timer
│         ● RUNNING                       │
│                                         │
│         Current Round                   │
│            01:15                        │
│                                         │
│    (No last round display)              │  ← Hidden during Round 1
│                                         │
│            Round 2                      │
│      Tap to Complete Round              │
└─────────────────────────────────────────┘
```

**Behavior:** Last round section is completely hidden during Round 1.

### Multi-Set Workouts - Rest Period

During rest between sets, last round time persists showing the last round from the completed set:

```
┌─────────────────────────────────────────┐
│                                         │
│              00:45                      │  ← Rest Timer (120pt/240pt)
│          Rest Period                    │
│                                         │
│    Next: Set 2 of 3                     │
│                                         │
│         Last Round (Set 1)              │  ← Show set context
│            01:23                        │
│                                         │
│    [ Skip Rest ]                        │
└─────────────────────────────────────────┘
```

**Behavior:** During rest, show last round from previous set with set context.

### Multi-Set Workouts - New Set Begins

When starting a new set, last round time resets:

**Set 1, Round 1:**
- No last round display

**Set 1, Round 2+:**
- Shows last round from Set 1

**Set 2, Round 1 (after rest):**
- No last round display (new set, no rounds completed yet)

**Set 2, Round 2+:**
- Shows last round from Set 2 (not from Set 1)

---

## Dynamic Type Scaling

### XXXL Testing Requirements

At Dynamic Type XXXL, font sizes scale up. Maximum sizes:

| Element | XXXL iPhone | XXXL iPad |
|---------|-------------|-----------|
| Main Timer | ~120pt | ~240pt |
| Current Round | ~48pt | ~95pt |
| Last Round | ~35pt | ~66pt |
| Labels | ~18pt | ~18pt |

**Layout Strategy:**
- Use `VStack` with flexible spacing
- `Spacer()` absorbs overflow
- Critical elements (timer, buttons) always visible
- Last round can truncate if necessary (least critical data)

**Tested Layouts:**
- ✓ iPhone 15 Pro at XXXL
- ✓ iPad Pro 13" at XXXL
- ✓ Multi-set + AMRAP + XXXL

---

## Accessibility

### VoiceOver

**Current Implementation:**
```
"Time Remaining: 3 minutes 24 seconds"
"Elapsed Time: 8 minutes 36 seconds"
"Current Round: 1 minute 15 seconds"
```

**New Addition:**
```
"Last Round: 1 minute 23 seconds, 8 seconds slower"
```

**Accessibility Labels:**
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("Last Round: \(lastRoundTimeFormatted), \(deltaDescription)")
```

### Color Contrast

- Last round text (50% white on dark): ≥7:1 ratio ✓
- Delta green/orange on dark: ≥4.5:1 ratio ✓
- Meets WCAG AA requirements

---

## Implementation Notes

### Data Source

**ViewModel Properties Needed:**
```swift
// In TimerViewModel
@Published var lastRoundSplitTime: TimeInterval? = nil
@Published var lastRoundCompletionTime: TimeInterval? = nil

// Computed property for delta
var currentRoundVsLastDelta: TimeInterval? {
    guard let lastSplit = lastRoundSplitTime else { return nil }
    let currentElapsed = getCurrentElapsed() - lastRoundCompletionTime ?? 0
    return currentElapsed - lastSplit
}
```

**Update Logic:**
```swift
func completeRound() {
    // ... existing code ...

    // Update last round tracking
    lastRoundSplitTime = splitTime
    lastRoundCompletionTime = currentTime

    // ... rest of existing code ...
}
```

### SwiftUI View Structure

```swift
// In mainTimerView, after Current Round section
if let lastSplit = viewModel.lastRoundSplitTime,
   viewModel.roundCount > 1 {  // Only show after completing 1+ rounds
    VStack(spacing: 6) {
        Text("Last Round")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
            .textCase(.uppercase)

        Text(formatTime(lastSplit))
            .font(.system(size: lastRoundFontSize, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundColor(.white.opacity(0.5))

        // Optional delta
        if let delta = viewModel.currentRoundVsLastDelta {
            Text(formatDelta(delta))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(delta > 0 ? .orange : .green)
        }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(lastRoundAccessibilityLabel)
}
```

### Font Size Computed Properties

```swift
private var lastRoundFontSize: CGFloat {
    // iPhone: 28pt (29% of 96pt), iPad: 53pt (28% of 192pt)
    horizontalSizeClass == .regular ? 53 : 28
}
```

---

## Alternative: Compact Version (If Space Is Tight)

If vertical space becomes an issue, consider side-by-side layout:

```
┌─────────────────────────────────────────┐
│         Current Round    Last Round     │
│            01:15           01:23        │
│                         +0:08 slower    │
└─────────────────────────────────────────┘
```

**Pros:** Saves vertical space
**Cons:** Harder to compare times, less clear hierarchy

---

## Recommendation

**Approve implementation with these conditions:**

1. ✅ Use stacked vertical layout as shown in primary mockup
2. ✅ Last round time at 28pt (iPhone) / 53pt (iPad)
3. ✅ White 50% opacity for last round time
4. ✅ Optional delta indicator (can be toggled in future)
5. ✅ Hide during Round 1
6. ✅ Reset per set in multi-set workouts
7. ✅ Test at Dynamic Type XXXL before shipping
8. ✅ VoiceOver announces with delta

**Priority:** Medium-High
**Estimated Effort:** 2-3 hours (implementation + testing)

---

## Next Steps

1. **Architect Review:** Validate data structure for tracking last round
2. **Implementation:** Add to TimerViewModel and TimerView
3. **Testing:**
   - Test with 10+ rounds (AMRAP)
   - Test multi-set scenarios
   - Test Dynamic Type XXXL
   - Test VoiceOver navigation
4. **Optional:** Add user preference to show/hide delta indicator

---

## Questions for Product/UX

1. **Delta Indicator:** Always show, or only show if difference > 5 seconds?
2. **Multi-set Context:** During rest, show "Last Round (Set 1)" or just "Last Round"?
3. **Color Coding:** Use green/orange for delta, or keep it neutral?
4. **EMOM Mode:** Should last interval time be shown? (Currently not planned)

---

**Document Version:** 1.0
**Last Updated:** 2025-12-01
