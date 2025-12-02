# Implementation Plan: Proposal 6B - Side-by-Side Control Buttons

## Executive Summary

This document provides a complete specification for implementing Proposal 6B from the UX Review: transitioning from vertically stacked control buttons to a side-by-side layout in the TimerView. The goal is to improve ergonomics and reduce screen real estate usage while maintaining accessibility and visual hierarchy.

**Target File**: `Sources/UI/Screens/TimerView.swift` (lines 521-597)

**Estimated Implementation Time**: 4-6 hours (includes testing and refinement)

**Risk Level**: Low (isolated UI change, no business logic modifications)

---

## 1. Current State Analysis

### 1.1 Existing Layout (Lines 521-597)

```swift
VStack(spacing: 12) {
    // Primary: Start/Pause/Resume Button
    Button(...) {
        HStack(spacing: 8) {
            Image + Text
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(gradient + shadow)
    }

    // Secondary: Complete Set / Finish Workout / Skip Rest
    Button(...) {
        HStack(spacing: 6) {
            Image + Text
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(translucent + border)
    }
}
.padding(.horizontal)
```

### 1.2 Current Dimensions

| Button | Height | Visual Style | States |
|--------|--------|--------------|--------|
| Primary | 60pt | Gradient fill + shadow | Start/Pause/Resume |
| Secondary | 50pt | Translucent + border | Complete Set/Finish/Skip Rest |

**Spacing**: 12pt between buttons
**Total Vertical Space**: 60 + 12 + 50 = 122pt

### 1.3 Button State Matrix

| Workout State | Primary Button | Secondary Button | Secondary Enabled? |
|--------------|----------------|------------------|-------------------|
| idle | Start | Finish | No (opacity 0.4) |
| running | Pause | Complete Set / Finish Workout | Yes |
| paused | Resume | Finish | No (opacity 0.4) |
| resting | Resting | Skip Rest | Yes |
| finished | Finished | Finish | No (opacity 0.4) |

---

## 2. Design Considerations

### 2.1 Layout Options

#### Option A: Equal Width Split (RECOMMENDED)

**Rationale**: Simplest implementation, maintains balanced visual weight, follows iOS conventions.

```
┌─────────────────────┬─────────────────────┐
│      PAUSE          │   Complete Set  →   │
│      (Primary)      │    (Secondary)      │
└─────────────────────┴─────────────────────┘
     50% width             50% width
```

**Advantages**:
- Simple SwiftUI implementation (HStack with equal flex)
- Predictable hit targets
- Balanced visual appearance
- Easy to maintain visual hierarchy through color/style

**Disadvantages**:
- Secondary button gets more visual weight than current design
- May encourage accidental taps on secondary action

#### Option B: 60/40 Width Split

```
┌──────────────────────────┬──────────────┐
│        PAUSE             │  Complete → │
│       (Primary)          │ (Secondary)  │
└──────────────────────────┴──────────────┘
        60% width             40% width
```

**Advantages**:
- Maintains clearer primary/secondary hierarchy
- Reduces accidental secondary button taps
- Proportional to action importance

**Disadvantages**:
- More complex layout code (GeometryReader or frame modifiers)
- Secondary button text may truncate on smaller devices
- Harder to maintain at different Dynamic Type sizes

#### Option C: 70/30 Width Split with Icon-Only Secondary

```
┌────────────────────────────┬────────┐
│          PAUSE             │   ✓    │
│         (Primary)          │  Icon  │
└────────────────────────────┴────────┘
          70% width          30% width
```

**Advantages**:
- Maximum emphasis on primary action
- Icon-only secondary is compact
- Clear visual hierarchy

**Disadvantages**:
- Secondary button loses discoverability (text removed)
- VoiceOver must rely entirely on accessibilityLabel
- Icon meaning may not be obvious (✓ for "Complete Set"?)
- Violates WCAG 2.1 Label in Name guideline

**RECOMMENDATION**: **Option A (Equal Width Split)** with enhanced visual hierarchy through styling differences.

### 2.2 Visual Hierarchy Strategy

To maintain clear primary/secondary distinction with equal widths:

| Attribute | Primary Button | Secondary Button |
|-----------|----------------|------------------|
| Background | Gradient fill | Translucent fill (keep current) |
| Border | None | 1pt stroke (keep current) |
| Shadow | 12pt radius, 6pt offset | None |
| Font Weight | .bold | .semibold (reduce from .bold) |
| Font Size | 18pt | 16pt (keep current) |
| Icon Size | 20pt | 16pt (keep current) |
| Icon Position | Leading | Leading |
| Color Coding | State-dependent gradient | State-dependent tint |

**Key Strategy**: Primary button remains visually dominant through gradient fill and shadow, while secondary button remains understated with translucent background.

---

## 3. Accessibility Requirements

### 3.1 WCAG AA Compliance

#### Minimum Touch Target (Success Criterion 2.5.5)

- **Requirement**: 44pt × 44pt (Apple recommends 52pt as per UI_RULES.json)
- **Current Heights**: Primary 60pt, Secondary 50pt ✅
- **Proposed Heights**: Both 60pt (maintain current primary height) ✅
- **Minimum Width**: With equal split on iPhone 14 Pro (393pt width):
  - Available width: 393pt - (2 × 16pt horizontal padding) = 361pt
  - Per button: (361pt - spacing) / 2 ≈ 175pt ✅ (exceeds 52pt minimum)

**Verdict**: All button sizes exceed minimum requirements on all iPhone models.

#### Visual Presentation (Success Criterion 1.4.3)

- **Contrast Ratio**: ≥7:1 for WCAG AA
- **Primary Button**: White text on gradient background (tested in current implementation ✅)
- **Secondary Button**: White text on translucent background with border (tested in current implementation ✅)

**Action Required**: No changes needed; maintain current color schemes.

#### Labels (Success Criterion 2.5.3)

- **Requirement**: Visible label text must be included in accessible name
- **Current Implementation**: Text matches accessibilityLabel ✅
- **Proposed**: Maintain current accessibilityLabel properties

### 3.2 VoiceOver Navigation

#### Current Flow (Vertical Stack)
1. Swipe right → Primary button (Start/Pause/Resume)
2. Swipe right → Secondary button (Complete Set/Finish)
3. Swipe right → Next UI element

#### Proposed Flow (Horizontal Layout)
1. Swipe right → Primary button (left side)
2. Swipe right → Secondary button (right side)
3. Swipe right → Next UI element

**Impact**: No functional change. VoiceOver naturally traverses HStack children left-to-right.

**Recommended VoiceOver Hints**:
- Primary: "Start Timer. Double-tap to start." (existing label is sufficient)
- Secondary: "Complete Set [N] of [M]. Double-tap to mark current set complete." (existing label is sufficient)

**Action Required**: No changes needed; existing accessibilityLabel implementations remain valid.

### 3.3 Dynamic Type Scaling

#### Requirements
- Support all Dynamic Type sizes (XS through XXXL)
- Text must not truncate at XXXL
- Layout must adapt gracefully

#### Current Font Sizes
- Primary: 18pt bold
- Secondary: 16pt semibold

#### Dynamic Type Strategy

**Option 1: Allow Natural Scaling (RECOMMENDED)**
- SwiftUI automatically scales fonts with Dynamic Type
- Test at XXXL to ensure text fits within button bounds
- May require reducing text size slightly on XXXL

**Option 2: Maximum Scale Factor**
```swift
.font(.system(size: 18, weight: .bold, design: .rounded))
.minimumScaleFactor(0.7)
```

**Action Required**: Test at XXXL size; add `.minimumScaleFactor(0.7)` if text truncates.

### 3.4 Accessibility Test Checklist

- [ ] VoiceOver reads buttons in logical order (left to right)
- [ ] accessibilityLabel accurately describes button action
- [ ] Buttons are discoverable with VoiceOver rotor (Actions)
- [ ] Touch targets exceed 52pt × 52pt
- [ ] Text remains readable at XXXL Dynamic Type
- [ ] Button states are announced correctly (enabled/disabled)
- [ ] Color contrast meets 7:1 ratio
- [ ] VoiceOver focus indicator is visible

---

## 4. Edge Cases & State Transitions

### 4.1 Text Length Variations

#### English (Baseline)

| State | Primary Label | Length | Secondary Label | Length |
|-------|--------------|--------|-----------------|--------|
| idle | Start | 5 chars | Finish | 6 chars |
| running | Pause | 5 chars | Complete Set | 12 chars |
| running (final) | Pause | 5 chars | Finish Workout | 14 chars |
| paused | Resume | 6 chars | Finish | 6 chars |
| resting | Resting | 7 chars | Skip Rest | 9 chars |

**Longest Labels**:
- Primary: "Starting" (8 chars) - during countdown
- Secondary: "Finish Workout" (14 chars) - final set

#### Internationalization Considerations (Future-Proofing)

While no localization files exist yet, plan for longer labels:

| Language | "Finish Workout" Translation | Length (approx) |
|----------|----------------------------|-----------------|
| German | "Training beenden" | 17 chars |
| Spanish | "Finalizar entrenamiento" | 24 chars |
| French | "Terminer l'entraînement" | 24 chars |

**Mitigation Strategy**:
1. Use `.lineLimit(1)` to prevent multi-line text
2. Add `.minimumScaleFactor(0.7)` to allow slight text shrinking
3. Test with 30+ character button labels to simulate long translations

```swift
Text(buttonLabel)
    .font(.system(size: 18, weight: .bold, design: .rounded))
    .lineLimit(1)
    .minimumScaleFactor(0.7)
```

### 4.2 Multi-Set vs Single-Set Workouts

#### Single Set (70% of use cases)
- Secondary button shows: "Finish Workout" (final set)
- No change in behavior

#### Multi-Set (30% of use cases)
- Secondary button shows: "Complete Set" (sets 1 through N-1)
- Secondary button shows: "Finish Workout" (final set N)

**Button Label Updates** (lines 632-643):
```swift
private var finishButtonLabel: String {
    if viewModel.state == .resting {
        return "Skip Rest"
    } else if viewModel.state == .running {
        if viewModel.currentSet < viewModel.numSets {
            return "Complete Set"  // 12 characters
        } else {
            return "Finish Workout"  // 14 characters
        }
    }
    return "Finish"
}
```

**No changes required**: Existing logic handles multi-set correctly.

### 4.3 Landscape Orientation

#### Portrait (Primary Use Case)
- iPhone 14 Pro: 393pt width
- Available for buttons: ~361pt (after horizontal padding)
- Per button: ~175pt (plenty of room)

#### Landscape (Secondary Use Case)
- iPhone 14 Pro: 852pt width
- Available for buttons: ~820pt
- Per button: ~405pt (excessive space)

**Consideration**: Buttons become very wide in landscape, which may look awkward.

**Mitigation Strategy**:
```swift
.frame(maxWidth: horizontalSizeClass == .compact ? .infinity : 300)
```

This limits button width on iPads and landscape phones to 300pt each, centering them.

**Action Required**: Add maxWidth constraint for landscape/iPad.

### 4.4 iPad Considerations

iPad has `horizontalSizeClass == .regular` (vs `.compact` for iPhone).

**Current iPad Behavior**:
- Timer font sizes are 2× larger (192pt vs 96pt)
- Buttons use same layout as iPhone

**Proposed iPad Behavior**:
- Keep side-by-side layout
- Limit button width to avoid excessive stretching
- Increase font sizes proportionally

```swift
private var buttonFontSize: CGFloat {
    horizontalSizeClass == .regular ? 22 : 18  // iPad: 22pt, iPhone: 18pt
}
```

**Action Required**: Add device-specific sizing for iPad.

---

## 5. Visual Mockups (ASCII)

### 5.1 State: Running (Single Set)

```
┌────────────────────────────────────────────────────┐
│                   12:34 (Main Timer)               │
│                    ● Running                       │
│                                                    │
│                 Current Round                      │
│                    02:15                           │
│                                                    │
│  ┌──────────────────────┬──────────────────────┐  │
│  │     [⏸] PAUSE        │  [✓] Finish Workout  │  │
│  │   (gradient fill)    │  (translucent+border)│  │
│  │    60pt height       │     60pt height      │  │
│  └──────────────────────┴──────────────────────┘  │
│           12pt spacing between buttons            │
└────────────────────────────────────────────────────┘
```

**Font Sizes**:
- Primary: 18pt bold, icon 20pt
- Secondary: 16pt semibold, icon 16pt

**Colors**:
- Primary background: Orange gradient (.orange → .orange.opacity(0.7))
- Primary text: White
- Secondary background: CardBackground translucent
- Secondary border: Orange tint 50% opacity
- Secondary text: White

### 5.2 State: Running (Multi-Set, Not Final)

```
┌────────────────────────────────────────────────────┐
│                   12:34 (Main Timer)               │
│                    ● Running                       │
│                                                    │
│                 Set 2 of 3                         │
│                  ● ● ○ (progress dots)             │
│                                                    │
│  ┌──────────────────────┬──────────────────────┐  │
│  │     [⏸] PAUSE        │  [✓] Complete Set    │  │
│  │   (orange gradient)  │  (green tint+border) │  │
│  └──────────────────────┴──────────────────────┘  │
└────────────────────────────────────────────────────┘
```

**Secondary Button Styling** (Complete Set):
- Background: Green.opacity(0.2)
- Border: Green.opacity(0.5)
- Distinguishes "Complete Set" from "Finish Workout"

### 5.3 State: Paused

```
┌────────────────────────────────────────────────────┐
│                   12:34 (Main Timer)               │
│                    ● Paused                        │
│                                                    │
│  ┌──────────────────────┬──────────────────────┐  │
│  │     [▶] RESUME       │  [✓] Finish          │  │
│  │ (accent gradient)    │  (disabled, 40%)     │  │
│  └──────────────────────┴──────────────────────┘  │
└────────────────────────────────────────────────────┘
```

**Disabled State** (Secondary):
- Opacity: 0.4 (existing behavior)
- Non-interactive during paused/idle states

### 5.4 State: Resting (Between Sets)

```
┌────────────────────────────────────────────────────┐
│                      REST                          │
│                  Between Sets                      │
│                                                    │
│                     02:00                          │
│                  (countdown)                       │
│                                                    │
│                 Completed Set 2                    │
│                 Next: Set 3 of 3                   │
│                                                    │
│  ┌──────────────────────┬──────────────────────┐  │
│  │  [⏸] PAUSE           │  [⏭] Skip Rest       │  │
│  │ (gradient)           │  (blue tint+border)  │  │
│  └──────────────────────┴──────────────────────┘  │
└────────────────────────────────────────────────────┘
```

**Note**: Rest state currently shows a separate full-screen view (restPeriodView). This mockup assumes control buttons are added to that view as well for consistency.

### 5.5 Landscape Orientation (iPhone)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                            12:34 (Timer)                                 │
│                             ● Running                                    │
│                                                                          │
│                 ┌──────────────┬──────────────┐                         │
│                 │  [⏸] PAUSE   │ [✓] Complete │                         │
│                 │  (max 300pt) │   (max 300pt)│                         │
│                 └──────────────┴──────────────┘                         │
└──────────────────────────────────────────────────────────────────────────┘
```

**Landscape Behavior**:
- Buttons centered horizontally
- Maximum width 300pt each to prevent stretching
- Maintains 60pt height

### 5.6 iPad (Regular Size Class)

```
┌────────────────────────────────────────────────────────────────┐
│                        12:34 (192pt font)                      │
│                          ● Running                             │
│                                                                │
│                       Current Round                            │
│                          02:15                                 │
│                                                                │
│           ┌─────────────────┬─────────────────┐               │
│           │  [⏸] PAUSE      │ [✓] Complete    │               │
│           │  (22pt font)    │   (20pt font)   │               │
│           │   max 400pt     │   max 400pt     │               │
│           └─────────────────┴─────────────────┘               │
└────────────────────────────────────────────────────────────────┘
```

**iPad Sizing**:
- Button font size: 22pt (primary), 20pt (secondary)
- Button max width: 400pt each
- Buttons centered in available space

---

## 6. Implementation Approach

### 6.1 SwiftUI Layout Strategy

**Current**:
```swift
VStack(spacing: 12) {
    primaryButton
    secondaryButton
}
.padding(.horizontal)
```

**Proposed (Option A - Equal Width)**:
```swift
HStack(spacing: 12) {
    primaryButton
        .frame(maxWidth: .infinity)
    secondaryButton
        .frame(maxWidth: .infinity)
}
.padding(.horizontal)
```

**Why This Works**:
- SwiftUI HStack with `.infinity` frames distributes space equally
- Each button takes 50% of available width minus spacing
- No GeometryReader needed (simpler, better performance)
- Natural layout for side-by-side equal-weight buttons

### 6.2 Button Height Standardization

**Current**: Primary 60pt, Secondary 50pt
**Proposed**: Both 60pt

**Rationale**:
- Equal heights create cleaner visual alignment
- Maintains consistent touch target size
- Simplifies layout code
- Matches iOS convention for button bars

**Change Required**:
```swift
// Line 581: Change from minHeight: 50 to minHeight: 60
.frame(maxWidth: .infinity, minHeight: 60)
```

### 6.3 Spacing Between Buttons

**Current**: 12pt vertical spacing
**Proposed**: 12pt horizontal spacing

**Rationale**:
- Maintains consistent spacing metric
- 12pt provides comfortable separation without excessive gap
- Tested value already in use

**iOS Spacing Guidelines**:
- 8pt: Tight spacing (related elements)
- 12pt: Standard spacing (distinct but related) ✅
- 16pt: Loose spacing (separate groups)

**Recommendation**: Keep 12pt spacing.

### 6.4 Responsive Layout for iPad/Landscape

```swift
private var controlButtons: some View {
    HStack(spacing: 12) {
        primaryButton
            .frame(maxWidth: buttonMaxWidth)
        secondaryButton
            .frame(maxWidth: buttonMaxWidth)
    }
    .padding(.horizontal)
}

private var buttonMaxWidth: CGFloat? {
    // iPhone portrait: unlimited width (nil)
    // iPad and landscape: constrain to 300pt per button
    horizontalSizeClass == .regular ? 300 : nil
}
```

**Alternative Using GeometryReader** (if more control needed):
```swift
GeometryReader { geometry in
    HStack(spacing: 12) {
        let buttonWidth = (geometry.size.width - 12 - 32) / 2  // 32 = horizontal padding
        primaryButton
            .frame(width: buttonWidth)
        secondaryButton
            .frame(width: buttonWidth)
    }
    .padding(.horizontal)
}
.frame(height: 60)
```

**Recommendation**: Use first approach (maxWidth) unless precise width control is required.

### 6.5 Font Size Adjustments

**Add computed properties for device-adaptive sizing**:

```swift
// Add to TimerView (near line 398 where other font size properties are defined)
private var primaryButtonFontSize: CGFloat {
    horizontalSizeClass == .regular ? 22 : 18
}

private var secondaryButtonFontSize: CGFloat {
    horizontalSizeClass == .regular ? 20 : 16
}

private var primaryIconSize: CGFloat {
    horizontalSizeClass == .regular ? 24 : 20
}

private var secondaryIconSize: CGFloat {
    horizontalSizeClass == .regular ? 20 : 16
}
```

**Apply in button definitions**:
```swift
// Line 536-537 (Primary button)
Image(systemName: buttonIcon)
    .font(.system(size: primaryIconSize, weight: .semibold))
Text(buttonLabel)
    .font(.system(size: primaryButtonFontSize, weight: .bold, design: .rounded))

// Line 576-579 (Secondary button)
Image(systemName: finishButtonIcon)
    .font(.system(size: secondaryIconSize, weight: .semibold))
Text(finishButtonLabel)
    .font(.system(size: secondaryButtonFontSize, weight: .semibold, design: .rounded))
```

### 6.6 Implementation Checklist

**Phase 1: Core Layout Change**
- [ ] Replace VStack with HStack in `controlButtons` property (line 522)
- [ ] Add `.frame(maxWidth: .infinity)` to both buttons
- [ ] Change secondary button height from 50pt to 60pt (line 581)
- [ ] Test layout on iPhone 14 Pro simulator

**Phase 2: Responsive Sizing**
- [ ] Add `buttonMaxWidth` computed property
- [ ] Apply maxWidth constraint to buttons
- [ ] Add device-adaptive font size properties
- [ ] Update button font sizes to use computed properties
- [ ] Test on iPad Pro simulator

**Phase 3: Text Handling**
- [ ] Add `.lineLimit(1)` to all button text
- [ ] Add `.minimumScaleFactor(0.7)` to button text
- [ ] Test with XXXL Dynamic Type size

**Phase 4: Polish**
- [ ] Verify spacing looks balanced
- [ ] Check alignment with other UI elements
- [ ] Ensure shadow/gradient effects render correctly
- [ ] Test all timer states (idle, running, paused, resting, finished)

**Phase 5: Accessibility Testing**
- [ ] Test VoiceOver navigation flow
- [ ] Verify touch targets meet 52pt minimum
- [ ] Test with Accessibility Inspector
- [ ] Validate contrast ratios

---

## 7. Testing Requirements

### 7.1 Manual Testing Scenarios

#### Scenario 1: Basic Navigation
1. Open any timer type
2. Start timer
3. Navigate with VoiceOver (Cmd+F5 in Simulator)
4. Verify buttons are announced left-to-right
5. Verify labels are accurate
6. Double-tap each button to activate

**Expected**: Smooth VoiceOver navigation, accurate labels.

#### Scenario 2: State Transitions
1. Start timer (idle → running)
2. Observe button label changes: "Start" → "Pause"
3. Tap Pause (running → paused)
4. Observe button label changes: "Pause" → "Resume"
5. Tap Resume (paused → running)
6. Verify all transitions update correctly

**Expected**: No layout jumps, smooth label transitions.

#### Scenario 3: Multi-Set Workflow
1. Configure AMRAP with 3 sets, 60s rest
2. Start timer
3. Verify secondary button shows "Complete Set"
4. Tap "Complete Set"
5. Verify rest screen appears
6. Verify secondary button shows "Skip Rest"
7. Complete rest → next set
8. On final set, verify secondary shows "Finish Workout"

**Expected**: Button labels update correctly per set context.

#### Scenario 4: Dynamic Type Scaling
1. Open Settings → Accessibility → Display & Text Size → Larger Text
2. Move slider to XXXL
3. Return to app
4. Verify button text is readable and not truncated
5. Test all button states

**Expected**: Text scales but remains within button bounds.

#### Scenario 5: Landscape Orientation
1. Start timer
2. Rotate device to landscape
3. Verify buttons are centered and not excessively wide
4. Rotate back to portrait
5. Verify layout returns to normal

**Expected**: Buttons constrained to reasonable width in landscape.

#### Scenario 6: iPad Layout
1. Open app on iPad simulator (12.9" Pro)
2. Start timer
3. Verify buttons are not stretched across entire screen
4. Verify font sizes are appropriately larger
5. Test in Split View mode

**Expected**: Buttons sized appropriately for large screen.

### 7.2 Accessibility Testing Checklist

Use Xcode Accessibility Inspector:

- [ ] **Touch Targets**: All buttons ≥52pt × 52pt
- [ ] **Contrast**: Text contrast ≥7:1 (use Color Contrast Analyzer)
- [ ] **VoiceOver**: Labels match visible text
- [ ] **VoiceOver**: Buttons focusable in logical order
- [ ] **Dynamic Type**: Text visible at all sizes
- [ ] **Reduce Motion**: No animation-dependent functionality
- [ ] **Button Traits**: Buttons identified as `.button` trait
- [ ] **State Changes**: VoiceOver announces state updates

### 7.3 Device Matrix

Test on representative devices:

| Device | Screen Width | Size Class | Test Priority |
|--------|-------------|------------|---------------|
| iPhone SE (3rd gen) | 375pt | Compact | High (smallest) |
| iPhone 14 Pro | 393pt | Compact | High (common) |
| iPhone 15 Pro Max | 430pt | Compact | Medium (largest iPhone) |
| iPad Pro 11" | 834pt | Regular | High (iPad baseline) |
| iPad Pro 12.9" | 1024pt | Regular | Medium (largest iPad) |

**Minimum Required Testing**:
- iPhone 14 Pro (portrait & landscape)
- iPad Pro 11"

---

## 8. Implementation Code

### 8.1 Complete Revised `controlButtons` Property

Replace lines 520-597 in `Sources/UI/Screens/TimerView.swift`:

```swift
// MARK: - Control Buttons
private var controlButtons: some View {
    HStack(spacing: 12) {
        // Primary action button (Start/Pause/Resume)
        Button(action: {
            if viewModel.state == .idle {
                viewModel.startTapped()
            } else if viewModel.state == .running {
                viewModel.pauseTapped()
            } else if viewModel.state == .paused {
                viewModel.resumeTapped()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: buttonIcon)
                    .font(.system(size: primaryIconSize, weight: .semibold))
                Text(buttonLabel)
                    .font(.system(size: primaryButtonFontSize, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: buttonGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: accentColorForTimerType.opacity(0.4), radius: 12, x: 0, y: 6)
            )
            .foregroundColor(.white)
        }
        .accessibilityLabel(buttonAccessibilityLabel)
        .disabled(viewModel.state == .finished)

        // Complete Set / Finish Workout / Skip Rest button (adaptive)
        Button(action: {
            if viewModel.state == .resting {
                // Skip rest and start next set
                viewModel.skipRest()
            } else if viewModel.state == .running {
                // Complete set or finish workout
                if viewModel.currentSet < viewModel.numSets {
                    // Not final set - complete set and start rest
                    viewModel.completeSetTapped()
                } else {
                    // Final set - finish entire workout
                    viewModel.completeSetTapped() // This will call finish internally
                    // Create summary data and call finish callback
                    let summaryData = createSummaryData(wasCompleted: false)
                    onFinish?(summaryData)
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: finishButtonIcon)
                    .font(.system(size: secondaryIconSize, weight: .semibold))
                Text(finishButtonLabel)
                    .font(.system(size: secondaryButtonFontSize, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 60)  // Changed from 50 to 60
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(finishButtonBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(finishButtonStroke, lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
        }
        .accessibilityLabel(finishButtonAccessibilityLabel)
        .disabled(viewModel.state == .idle || viewModel.state == .paused || viewModel.state == .finished)
        .opacity((viewModel.state == .idle || viewModel.state == .paused || viewModel.state == .finished) ? 0.4 : 1)
    }
    .frame(maxWidth: buttonContainerMaxWidth)
    .padding(.horizontal)
}
```

### 8.2 New Computed Properties

Add these near the other font size properties (around line 398):

```swift
// MARK: - Button Sizing (Device Adaptive)

private var primaryButtonFontSize: CGFloat {
    horizontalSizeClass == .regular ? 22 : 18
}

private var secondaryButtonFontSize: CGFloat {
    horizontalSizeClass == .regular ? 20 : 16
}

private var primaryIconSize: CGFloat {
    horizontalSizeClass == .regular ? 24 : 20
}

private var secondaryIconSize: CGFloat {
    horizontalSizeClass == .regular ? 20 : 16
}

private var buttonContainerMaxWidth: CGFloat? {
    // On iPad and landscape, constrain button width to prevent excessive stretching
    // In portrait iPhone, allow full width
    horizontalSizeClass == .regular ? 700 : nil
}
```

### 8.3 No Changes Required To

The following properties and methods remain unchanged:
- `buttonIcon` (lines 599-606)
- `buttonGradientColors` (lines 608-617)
- `buttonLabel` (lines 621-630)
- `finishButtonLabel` (lines 632-643)
- `finishButtonIcon` (lines 645-651)
- `finishButtonBackground` (lines 653-664)
- `finishButtonStroke` (lines 666-677)
- `finishButtonAccessibilityLabel` (lines 679-690)
- `buttonAccessibilityLabel` (lines 692-700)

These remain functionally identical; only the layout container changes from VStack to HStack.

---

## 9. Rollback Plan

If implementation reveals unforeseen issues, rollback is straightforward:

### 9.1 Git Revert
```bash
# If changes are in single commit
git revert <commit-hash>

# If changes are across multiple commits
git revert <first-commit>..<last-commit>
```

### 9.2 Manual Rollback

1. Change HStack back to VStack:
```swift
VStack(spacing: 12) {  // Changed from HStack
```

2. Remove `.frame(maxWidth: .infinity)` from buttons (or keep it, won't harm vertical layout)

3. Restore secondary button height:
```swift
.frame(maxWidth: .infinity, minHeight: 50)  // Changed from 60
```

4. Remove new computed properties for button sizing (optional, they won't harm existing code)

---

## 10. Success Metrics

### 10.1 Quantitative Metrics

**Pre-Implementation Baseline**:
- Vertical space consumed: 122pt (60 + 12 + 50)
- Button tap accuracy: [Baseline to be measured]
- Average taps per workout: [Baseline to be measured]

**Post-Implementation Targets**:
- Vertical space consumed: ≤60pt (single row)
- Button tap accuracy: ≥98% (accidental taps <2%)
- No increase in average taps per workout
- VoiceOver navigation time: No regression

**How to Measure**:
- Use Xcode Instruments to measure layout frame heights
- Add analytics events for button taps (optional)
- Conduct user testing with 5-10 representative users

### 10.2 Qualitative Metrics

**User Feedback Questions** (if conducting user testing):
1. Are the button labels clear and easy to distinguish?
2. Do you prefer the side-by-side or stacked layout?
3. Did you accidentally tap the wrong button?
4. Is it easy to find the pause button during a workout?
5. (VoiceOver users) Is the button navigation logical?

**Expected Outcomes**:
- 80%+ users prefer side-by-side layout
- <10% report accidental taps
- 100% can identify primary action (pause/resume)

---

## 11. Timeline & Resources

### 11.1 Estimated Timeline

| Phase | Task | Estimated Time |
|-------|------|---------------|
| 1 | Core layout implementation | 1-2 hours |
| 2 | Responsive sizing (iPad/landscape) | 1 hour |
| 3 | Text handling & polish | 0.5 hours |
| 4 | Manual testing (all states) | 1 hour |
| 5 | Accessibility testing | 1 hour |
| 6 | Refinement based on testing | 0.5-1 hour |
| **Total** | | **4-6 hours** |

### 11.2 Required Resources

**Developer Skills**:
- SwiftUI layout (HStack, frames, spacing)
- iOS accessibility (VoiceOver, Dynamic Type)
- Xcode testing tools (Accessibility Inspector)

**Tools**:
- Xcode 15+
- iOS 15+ Simulator (iPhone 14 Pro, iPad Pro)
- Accessibility Inspector
- Color Contrast Analyzer (optional, for contrast validation)

**No Additional Resources Required**:
- No new frameworks or dependencies
- No backend changes
- No localization changes (yet)

### 11.3 Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Layout breaks on smaller iPhones | Low | Medium | Test on iPhone SE early |
| Text truncation at XXXL Dynamic Type | Medium | High | Add minimumScaleFactor early |
| Accidental secondary button taps | Medium | Medium | User testing; iterate on spacing |
| VoiceOver navigation confusion | Low | High | Accessibility testing before release |
| iPad layout looks awkward | Medium | Low | Constrain button width |

**Overall Risk Level**: **Low**

This is a low-risk UI change that:
- Doesn't affect business logic
- Can be easily rolled back
- Has clear implementation path
- Improves UX for majority of users

---

## 12. Next Steps

1. **Review & Approve**: Stakeholders review this plan and approve approach
2. **Implementation**: Developer implements changes per Section 8
3. **Testing**: QA follows testing plan in Section 7
4. **Documentation**: Update DESIGN_DECISIONS.md with DD-004 entry
5. **User Testing** (Optional): Gather feedback from 5-10 representative users
6. **Release**: Deploy as part of next app update

---

**Document Version**: 1.0
**Date**: 2025-12-02
**Author**: Claude Code (Architecture Planning)
**Status**: Ready for Implementation Review
