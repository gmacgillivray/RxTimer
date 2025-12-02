# Design Decisions

This document records significant design decisions made during the development of RxTimer, including proposals that were considered and rejected.

---

## DD-001: Rejection of Tap-to-Pause Interaction

**Date:** 2025-12-01
**Status:** REJECTED
**Decision Maker:** UX Design Team
**Related Proposal:** 6A from UX Review (December 2025)

### Proposal Summary

Remove the explicit pause button and allow users to pause the workout by tapping anywhere on the timer display (the large digit area showing elapsed/remaining time).

### Context

During a comprehensive UX review, stakeholders suggested simplifying the timer interface by removing the pause button and making the timer display itself tappable to pause/resume workouts. The goal was to:
- Reduce UI clutter
- Provide a larger, more accessible pause target
- Follow patterns seen in some video player interfaces

### Decision

**REJECTED** - This proposal poses critical safety risks and violates accessibility requirements.

### Reasoning

#### 1. Accidental Activation (Critical Safety Issue)

The timer display is the primary visual focus during high-intensity workouts:
- Users glance at the timer constantly (every few seconds)
- During CrossFit/HIIT workouts, users experience:
  - Impaired hand-eye coordination
  - Sweaty hands that slip on screens
  - Heavy breathing affecting stability
  - May rest hands/arms on device between exercises

**Consequence:** Accidental pauses would be frequent and highly disruptive to workout flow.

#### 2. Discoverability Failure

- No visual indication that the timer is tappable
- Hidden affordances violate iOS Human Interface Guidelines
- New users would not discover this function
- Conflicts with user mental model: timer displays information, buttons perform actions

#### 3. Accessibility Violation

**Current implementation:**
- Timer has `accessibilityLabel: "Time Remaining: [time]"` (informational role)
- Explicit pause button clearly labeled for VoiceOver users

**Proposed implementation would:**
- Change timer from informational to interactive without visual cues
- Create ambiguous touch targets (which part of the timer is tappable?)
- Confuse VoiceOver users who rely on explicit control labels
- Violate WCAG AA accessibility requirements for control clarity

#### 4. iOS Pattern Violation

Standard iOS patterns for timers:
- **Clock app:** Explicit pause/start buttons
- **Shortcuts timer:** Explicit pause button
- **Apple Watch workouts:** Dedicated pause gesture (cover screen with palm) + explicit button
- **Video players:** Tap-to-pause works because pause/play state is visually obvious (play triangle icon)

The timer display in a workout app does not provide clear pause/play state indication.

#### 5. Context Mismatch

Tap-to-pause works in contexts where:
- User is stationary and focused on screen (watching video)
- Accidental taps are rare
- Pause state is visually obvious

Workout context is different:
- User is moving, sweating, breathing hard
- Device may be on floor, bench, or wall-mounted
- Accidental touches are common
- Focus is divided between exercise and timer

#### 6. Loss of Visual Feedback

**Current behavior:**
- Pause button changes appearance: "Pause" → "Resume"
- Icon changes: pause.fill → play.fill
- Clear state indication

**Proposed behavior:**
- No explicit state change on timer display
- Would require additional state indicator (defeating the "simplification" goal)

### Alternative Considered

If tap-based pause is desired in the future, consider:
- **Apple Watch-style gesture:** Cover entire screen with palm (requires proximity sensor, deliberate action)
- **Long press to pause:** Requires sustained touch (2+ seconds), reduces accidental activation
- **Dual confirmation:** First tap shows "Tap again to pause" state for 2 seconds

All alternatives require explicit user testing before implementation.

### References

- UX Review Document: `Specs/UX_REVIEW_AND_RECOMMENDATIONS.md`
- iOS Human Interface Guidelines: Controls and Feedback
- WCAG 2.1 AA: Guideline 3.2 (Predictable)
- Apple Watch Workout UI Patterns

### Stakeholder Notes

If this proposal is reconsidered in the future, it MUST include:
1. User testing with actual athletes during high-intensity workouts
2. Measurement of accidental pause rate
3. VoiceOver user testing
4. iOS accessibility compliance review

**Do not implement without these validations.**

---

## DD-002: Countdown Audio Simplification

**Date:** 2025-12-01
**Status:** APPROVED & IMPLEMENTED
**Decision Maker:** UX Design Team
**Related Proposal:** 3 from UX Review (December 2025)

### Proposal Summary

Remove continuous tick sounds during countdown; play beep sounds only at 3, 2, and 1 seconds.

### Context

Original implementation played tick sounds every second during the 10-second countdown phase. Stakeholders suggested simplifying audio feedback to reduce cognitive load during workout preparation.

### Decision

**APPROVED** - Implemented with actual beep sounds (not voice).

### Reasoning

1. **Reduces Cognitive Load**
   - Countdown is preparation phase, not active timing
   - Users don't need granular second-by-second audio feedback
   - Continuous ticks create unnecessary tension

2. **Clearer Transition Markers**
   - 3-2-1 beeps become more distinctive without tick background
   - Provides clear "get ready" signal at 3 seconds
   - Final countdown sequence is more dramatic and effective

3. **Matches User Mental Model**
   - Countdown is distinct from active workout timing
   - System timers typically use discrete beeps for countdown
   - Follows pattern established by iOS Clock app and similar applications

4. **Audio Pattern Consistency**
   - Beeps at 3-2-1 match common countdown patterns
   - Start sound at 0 clearly signals workout begin
   - Distinct audio signature for countdown vs. workout phases

### Implementation

**Files Modified:**
- `Sources/Domain/Engine/TimerEngine.swift` (lines 317-324)
- `Sources/UI/ViewModels/TimerViewModel.swift` (lines 500-502, 507-509)

**Audio File Used:**
- `Resources/Audio/beep_1hz.caf` (actual electronic beep, not voice)

**Events Emitted:**
- `countdown_3` at 3 seconds remaining
- `countdown_2` at 2 seconds remaining
- `countdown_1` at 1 second remaining
- `start` at 0 seconds (workout begins)

### Accessibility Considerations

- Visual countdown remains (large numbers: 120pt iPhone, 240pt iPad)
- Haptic feedback provides non-audio alternative
- VoiceOver announces countdown numbers alongside beeps
- Maintains WCAG AA compliance

### Testing

Tested on iPhone 17 simulator. Countdown sequence verified:
- Silent from 10-4 seconds
- Beep at 3, 2, 1 seconds
- Start sound at workout begin
- No regression in state transitions

### References

- Implementation PR: [To be added]
- UX Review: `Specs/UX_REVIEW_AND_RECOMMENDATIONS.md`
- Audio Specifications: `Specs/EVENTS_TO_CUES.md`

---

## DD-003: VoiceOver Round Completion Announcements

**Date:** 2025-12-01
**Status:** APPROVED & IMPLEMENTED
**Decision Maker:** UX Design Team, Accessibility Review

### Proposal Summary

Add VoiceOver announcements when users complete rounds during AMRAP and For Time workouts.

### Context

Round counter button had visual and haptic feedback for round completion, but no audio feedback for VoiceOver users. This created an accessibility gap where blind/low-vision users didn't receive confirmation of their action.

### Decision

**APPROVED** - Implemented with natural language time formatting.

### Reasoning

1. **Accessibility Requirement**
   - WCAG 2.1 AA requires feedback for user actions
   - VoiceOver users need confirmation that round was recorded
   - Current implementation only provided visual feedback

2. **Performance Feedback**
   - Announces split time for the completed round
   - Provides immediate performance data to VoiceOver users
   - Enables real-time pacing decisions during workout

3. **Low Implementation Cost**
   - Uses standard `UIAccessibility.post()` API
   - Natural language formatter improves comprehension
   - No impact on sighted users

### Implementation

**Files Modified:**
- `Sources/UI/ViewModels/TimerViewModel.swift` (lines 234-239, 503-522)

**Announcement Format:**
```
"Round [number] completed. Split time: [time in natural language]"
```

**Examples:**
- "Round 1 completed. Split time: 45 seconds"
- "Round 2 completed. Split time: 1 minute 23 seconds"
- "Round 3 completed. Split time: 2 minutes 5 seconds"

**Natural Language Time Formatting:**
Created `formatTimeForVoiceOver()` helper that converts:
- `65 seconds` → "1 minute 5 seconds"
- `125 seconds` → "2 minutes 5 seconds"
- `3665 seconds` → "1 hour 1 minute 5 seconds"

### Accessibility Considerations

- Announcement uses `.announcement` notification (non-interruptive)
- Does not interfere with workout audio (music, podcasts)
- VoiceOver users can configure speech rate and volume
- Maintains existing visual and haptic feedback for sighted users

### Testing

To test:
1. Enable VoiceOver (Cmd+F5 in Simulator)
2. Start AMRAP or For Time workout
3. Tap "Complete Round" button
4. Listen for announcement with split time

### References

- Implementation PR: [To be added]
- WCAG 2.1 Guideline 3.3.1: Error Identification
- iOS Accessibility Guidelines: Feedback for Actions
- UX Review: `Specs/UX_REVIEW_AND_RECOMMENDATIONS.md`

---

## Decision Template

For future design decisions, use this template:

### DD-XXX: [Decision Title]

**Date:** YYYY-MM-DD
**Status:** PROPOSED | APPROVED | REJECTED | SUPERSEDED
**Decision Maker:** [Team/Role]
**Related Proposal:** [Reference if applicable]

#### Proposal Summary
[Brief description of what was proposed]

#### Context
[Why this decision was needed, background information]

#### Decision
[APPROVED/REJECTED and key outcome]

#### Reasoning
[Bullet points explaining the decision rationale]

#### Implementation (if approved)
[Technical details, files modified, API changes]

#### Alternatives Considered (if any)
[Other options and why they weren't chosen]

#### References
[Links to related documents, PRs, external guidelines]

---

## Change Log

| Date | Decision | Status | Summary |
|------|----------|--------|---------|
| 2025-12-01 | DD-001 | REJECTED | Tap-to-pause interaction |
| 2025-12-01 | DD-002 | APPROVED | Countdown audio simplification |
| 2025-12-01 | DD-003 | APPROVED | VoiceOver round announcements |
