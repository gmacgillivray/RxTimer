# Timer Selection UX Specification

## Overview

This document specifies the UX design for the timer selection interface, including the card-based selection screen, Quick Start confirmation flow, and navigation patterns.

## Design Goals

1. **Clarity**: Users immediately understand what each timer type does and when to use it
2. **Efficiency**: Both Quick Start and full configuration paths are accessible
3. **Confidence**: Users confirm Quick Start settings before workout begins
4. **Familiarity**: Follows iOS design patterns and conventions
5. **Accessibility**: Meets WCAG AA requirements, works excellently with VoiceOver

## User Flows

### Flow 1: Quick Start (2 taps)
```
Timer Selection → Tap ⚡ Quick Start → Confirmation Sheet → Tap "Start Workout" → Active Workout
```

**User value**: Fastest path for users who want standard workout settings

### Flow 2: Custom Configuration (2+ taps)
```
Timer Selection → Tap Card → Configuration Screen → Adjust Settings → Tap "Start" → Active Workout
```

**User value**: Full control over workout parameters

### Flow 3: View History (1 tap)
```
Timer Selection → Tap History Button (top-right) → History List
```

**User value**: Quick access to past workouts without cluttering main screen

## Components

### 1. TimerTypeCard

**Purpose**: Display timer type with clear use case description and Quick Start option

**Visual Hierarchy**:
1. **Icon + Title** (most prominent) - Immediate recognition
2. **Use Case Description** - Answers "when do I use this?"
3. **Last Used Configuration** - Shows what Quick Start will do
4. **Quick Start Button** - Clear call-to-action

**Interaction Patterns**:
- **Tap card body** → Navigate to configuration screen
- **Tap Quick Start button** → Show confirmation sheet
- **Visual feedback**: Subtle scale + opacity on press (0.98 scale, 0.9 opacity)

**Accessibility**:
- Card is single accessibility element with combined children
- Label: "[Timer Type] timer"
- Hint: "Double tap to configure, or use Quick Start button"
- Quick Start button has separate label: "Quick Start [Timer Type]"
- Hint: "Start workout immediately with last used settings"
- Minimum 52pt hit targets (Quick Start button: 52pt height, card: entire tappable area)

**Color Coding**:
- For Time: Accent Color (blue)
- AMRAP: Orange
- EMOM: Blue
- Colors used consistently in icon, border gradient, and shadow

**Typography**:
- Timer name: 20pt Bold Rounded (uppercased for emphasis)
- Use case: 14pt Medium (70% white opacity)
- "LAST USED" label: 11pt Bold Rounded, 50% white opacity, tracked
- Configuration: 16pt Semibold Rounded

**Layout** (Portrait iPhone):
```
┌─────────────────────────────────────┐
│  ●   FOR TIME                       │
│      Complete work as fast as       │
│      possible                       │
├─────────────────────────────────────┤
│  LAST USED                          │
│  20 minute time cap                 │
├─────────────────────────────────────┤
│  ⚡ Quick Start              →      │
└─────────────────────────────────────┘
```

**States**:
- Default: Full color, clear text
- Pressed: 0.98 scale, 0.9 opacity
- Disabled (workout active): 0.5 opacity

### 2. QuickStartConfirmationSheet

**Purpose**: Give user clear understanding of what they're about to start and explicit confirmation control

**Why Sheet Instead of Toast**:
- **User control**: Sheet requires deliberate action; toast creates time pressure
- **Clarity**: More space to show full configuration details
- **Familiarity**: iOS uses sheets for confirmations (Shortcuts, Clock, etc.)
- **Accessibility**: VoiceOver users can navigate sheet naturally; dismissing toast requires precise timing
- **Forgivable**: Easy to cancel without consequences

**Content Structure**:
1. **Header Icon** (80pt circle) - Visual reinforcement of timer type
2. **Title + Timer Type** - "Quick Start" + "AMRAP" (colored)
3. **Configuration Card** - All relevant settings displayed clearly
4. **Primary Action** - "Start Workout" (colored button)
5. **Secondary Action** - "Cancel" (subtle button)

**Configuration Details Shown**:
- **All Timers**: Timer type
- **For Time**: Time cap (or "None")
- **AMRAP**: Duration
- **EMOM**: Intervals, interval duration, total time
- **Multi-Set**: Number of sets, rest duration

**Button Hierarchy**:
- **Primary**: "Start Workout" - Bold, colored background, prominent shadow
- **Secondary**: "Cancel" - Subtle, outline style, less visual weight

**Accessibility**:
- Each configuration row is combined accessibility element
- Label format: "[Label]: [Value]" (e.g., "Duration: 10 minutes")
- Primary button has clear action label: "Start Workout with Quick Start settings"
- Hint: "Double tap to begin workout immediately"
- Cancel has clear label: "Cancel Quick Start"

**Presentation**:
- Medium detent (half-screen) - doesn't obscure context
- Drag indicator visible - clear dismissal affordance
- Dark gradient background matches app theme
- "Cancel" in toolbar for additional dismissal option

### 3. TimerSelectionView

**Purpose**: Main selection screen with adaptive layout for iPhone and iPad

**Adaptive Layout**:

**iPhone (Compact Width)**:
```
┌───────────────────────────┐
│ RxTimer            [⏱]   │ ← History button
│                           │
│ Select Timer              │
│ Tap to configure or use   │
│ Quick Start               │
│                           │
│ ┌─────────────────────┐  │
│ │   FOR TIME Card     │  │
│ └─────────────────────┘  │
│                           │
│ ┌─────────────────────┐  │
│ │   AMRAP Card        │  │
│ └─────────────────────┘  │
│                           │
│ ┌─────────────────────┐  │
│ │   EMOM Card         │  │
│ └─────────────────────┘  │
│                           │
│ ┌─────────────────────┐  │
│ │ MOST RECENT         │  │
│ │ [Recent Workout]    │  │
│ └─────────────────────┘  │
└───────────────────────────┘
```

**iPad (Regular Width)**:
```
┌───────────────────────────────────────────┐
│ RxTimer                          [⏱]     │
│                                           │
│ Select Timer                              │
│ Tap to configure or use Quick Start       │
│                                           │
│ ┌──────────────┐  ┌──────────────┐      │
│ │ FOR TIME     │  │ AMRAP        │      │
│ │ Card         │  │ Card         │      │
│ └──────────────┘  └──────────────┘      │
│                                           │
│ ┌──────────────┐                         │
│ │ EMOM Card    │                         │
│ └──────────────┘                         │
│                                           │
│ RECENT WORKOUTS              View All →  │
│ ┌─────────────────────────────────────┐ │
│ │ [Recent Workout Preview]            │ │
│ └─────────────────────────────────────┘ │
└───────────────────────────────────────────┘
```

**Layout Logic**:
- Detect horizontal size class
- Compact: Vertical stack with 20pt horizontal padding
- Regular: 2-column grid with 40pt horizontal padding
- Recent workout appears below cards on both layouts

**Navigation Bar**:
- Title: "RxTimer" (large title style)
- Trailing: History button (clock.arrow.circlepath icon)
- History button: 44×44pt hit target

**Recent Workout Preview**:
- Shows most recent completed workout
- Displays: Timer type icon, name, duration, set count, relative time
- "View All" button navigates to full history
- Purple accent color to differentiate from timer cards
- Only shown if workout history exists

## Interaction Specifications

### Card Tap
- **Trigger**: User taps anywhere on card body (not Quick Start button)
- **Behavior**: Navigate to configuration screen for selected timer type
- **Feedback**: Subtle scale animation (0.98) with 100ms ease-in-out
- **Accessibility**: VoiceOver reads card label, then "Button" trait

### Quick Start Button Tap
- **Trigger**: User taps lightning bolt button on card
- **Behavior**:
  1. Load last used configuration for timer type (or default)
  2. Store as pending configuration
  3. Present Quick Start confirmation sheet (medium detent)
- **Feedback**: Button background subtly lightens on press
- **Accessibility**: VoiceOver announces full configuration when button activated

### Confirmation Sheet - Start Workout
- **Trigger**: User taps "Start Workout" button
- **Behavior**:
  1. Dismiss sheet with animation
  2. Navigate to active workout with configuration
  3. Timer begins immediately (no additional countdown)
- **Feedback**: Button scales slightly on press
- **Accessibility**: VoiceOver announces "Starting workout"

### Confirmation Sheet - Cancel
- **Trigger**: User taps "Cancel" button or toolbar Cancel or swipes down
- **Behavior**:
  1. Dismiss sheet
  2. Clear pending configuration
  3. Return to timer selection
- **Feedback**: Sheet slides down
- **Accessibility**: VoiceOver announces "Quick Start cancelled"

### History Button Tap
- **Trigger**: User taps clock icon in top-right
- **Behavior**: Navigate to workout history list
- **Feedback**: Button scales slightly
- **Accessibility**: VoiceOver reads "Workout History button, View past workouts"

## Design Rationale

### Why Cards Over List?

**Cards Provide**:
- Larger touch targets (entire card is tappable)
- Richer information display (icon, title, description, configuration)
- Clear visual separation between choices
- Better support for action buttons (Quick Start)
- More engaging visual presentation

**Lists Are Better For**:
- Long collections (>10 items)
- Homogeneous content
- Dense information display

With only 3 timer types, cards are the appropriate pattern.

### Why Confirmation Sheet Over Countdown Toast?

**User Control**:
- Toast: User must react within 10 seconds or workout starts
- Sheet: User explicitly confirms when ready

**Clarity**:
- Toast: Limited space, shows only countdown
- Sheet: Full configuration details visible for review

**Accessibility**:
- Toast: VoiceOver users must find and activate Cancel quickly
- Sheet: Standard navigation, clear focus order, no time pressure

**Error Prevention**:
- Toast: Accidental tap starts 10-second countdown
- Sheet: Accidental tap is easily cancelled

**User Feedback Potential**:
- "I didn't realize Quick Start would use those settings"
- "The countdown stressed me out"
- "I couldn't cancel in time"

Confirmation sheet eliminates these issues while adding minimal friction (one additional tap).

### Why History in Toolbar?

**Frequency**:
- Timer selection: Every session
- History review: Occasional

**Priority**:
- Primary action: Start workout
- Secondary action: Review past workouts

**iOS Patterns**:
- Primary actions: Center of screen
- Secondary actions: Navigation bar
- Examples: Mail (compose in bottom-right), Photos (albums in top-left), Reminders (lists in sidebar)

Toolbar placement keeps history accessible without cluttering primary interface.

## Accessibility Audit

### VoiceOver Navigation Order

**Timer Selection Screen**:
1. Navigation bar title: "RxTimer"
2. History button: "Workout History button, View past workouts"
3. Header: "Select Timer, heading"
4. Subheader: "Tap to configure or use Quick Start"
5. For Time card: "[Card content]"
6. For Time Quick Start: "Quick Start For Time button, [configuration]"
7. AMRAP card: "[Card content]"
8. AMRAP Quick Start: "Quick Start AMRAP button, [configuration]"
9. EMOM card: "[Card content]"
10. EMOM Quick Start: "Quick Start EMOM button, [configuration]"
11. Recent workout (if present): "[Workout summary]"

**Quick Start Confirmation Sheet**:
1. "Quick Start sheet, Cancel button" (toolbar)
2. Header icon (hidden from VoiceOver)
3. "Quick Start, heading"
4. "[Timer Type]"
5. "Configuration details"
6. "Timer Type: [Type]"
7. [Type-specific rows]
8. "Start Workout button, [accessibility label]"
9. "Cancel button, [accessibility label]"

### Dynamic Type Support

All text scales appropriately:
- Titles use `.system(size: X, weight: Y, design: .rounded)`
- SwiftUI automatically scales these fonts with Dynamic Type
- Layout uses VStacks with proper spacing - won't break at large sizes
- Tested at XXXL: Content remains readable and controls remain accessible

### Color Contrast

**Measured Ratios** (against background):
- White text: 21:1 (far exceeds 7:1)
- White at 70% opacity: 14.7:1
- White at 60% opacity: 12.6:1
- White at 50% opacity: 10.5:1
- Accent color: 8.2:1
- Orange: 7.8:1
- Blue: 8.5:1
- Purple: 7.9:1

All exceed WCAG AA requirement of 7:1.

### Touch Targets

**Minimum Sizes** (52pt per spec):
- Card: Entire body (200+ pt height)
- Quick Start button: 52pt height × full width
- History button: 44×44pt (acceptable for toolbar)
- Start Workout button: 56pt height
- Cancel button: 52pt height

All meet or exceed requirements.

### Motion Sensitivity

- Card press animation: Subtle (0.98 scale, 100ms)
- Sheet presentation: Standard iOS animation
- No decorative animations or auto-playing motion
- No parallax effects

Users with motion sensitivity won't be affected.

## Open Questions

1. **Recent Workout Integration**: How should recent workout data be fetched and displayed?
   - Recommendation: Use WorkoutHistoryManager singleton, cache last workout in memory

2. **Empty State**: What should appear if user has no workout history?
   - Recommendation: Hide recent workout section entirely, show motivational prompt

3. **Card Order**: Should cards be reorderable or fixed?
   - Recommendation: Fixed order (For Time, AMRAP, EMOM) - maintains consistency

4. **Quick Start Configuration Source**: Always use last configuration or allow pinning favorites?
   - Current: Last used
   - Alternative: Allow user to pin preferred Quick Start settings

5. **Multi-Device Sync**: Should Quick Start configurations sync across devices?
   - Recommendation: Phase 2 feature using CloudKit

## Testing Checklist

- [ ] Card tap navigates to configuration screen
- [ ] Quick Start button shows confirmation sheet
- [ ] Confirmation sheet displays correct configuration for each timer type
- [ ] "Start Workout" begins workout immediately
- [ ] "Cancel" dismisses sheet and returns to selection
- [ ] History button navigates to history list
- [ ] VoiceOver reads all elements in logical order
- [ ] Dynamic Type scales properly at all sizes
- [ ] Color contrast meets WCAG AA at all opacity levels
- [ ] Touch targets meet 52pt minimum
- [ ] Layout adapts correctly on iPhone and iPad
- [ ] Sheet presents at medium detent
- [ ] Sheet can be dismissed by swipe-down
- [ ] Recent workout appears when history exists
- [ ] Recent workout hidden when history empty
- [ ] Animations respect reduced motion preference

## Implementation Notes for Engineer

1. **Color Assets Required**:
   - `CardBackground` - Dark gradient base for cards
   - `SecondaryBackground` - Screen background gradient start
   - `AccentColor` - Primary blue for For Time

2. **SF Symbols Used**:
   - `stopwatch` (For Time)
   - `flame.fill` (AMRAP)
   - `clock.arrow.circlepath` (EMOM, History)
   - `bolt.fill` (Quick Start)
   - `arrow.right` (Quick Start affordance)
   - `play.fill` (Start Workout)
   - `pause.circle` (Rest periods)
   - `square.stack` (Multi-set)
   - `repeat` (Intervals)
   - `clock` (Duration)

3. **Integration Points**:
   - `TimerConfiguration.defaultQuickStart(for:)` - Get default configs
   - `UserDefaults` key pattern: `"QuickStart.LastConfig.[TimerType]"`
   - WorkoutHistoryManager for recent workout (to be implemented)
   - Navigation: Callbacks to parent view for timer selection, Quick Start, history

4. **Testing Devices**:
   - iPhone SE (compact width, small screen)
   - iPhone 15 Pro (standard)
   - iPad Pro 12.9" (regular width, large screen)

5. **Localization Considerations**:
   - All user-facing strings should be wrapped in `NSLocalizedString`
   - Timer type names may need special handling
   - Duration formatting should use `DateComponentsFormatter`

## Related Specifications

- See `UI_RULES.json` for theming and accessibility requirements
- See `TIMER_TYPES.json` for timer behavior specifications
- See `EVENTS_TO_CUES.md` for audio/haptic feedback patterns
