# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**RxTimer** is a SwiftUI iOS application implementing three CrossFit-style timer modes:
- **For Time (FT)**: Counts up with optional time cap
- **AMRAP** (As Many Rounds As Possible): Counts down with interval warnings
- **EMOM** (Every Minute On the Minute): Interval-based with dual display

**App Name**: RxTimer - Precision Timer for Athletes
**Tagline**: "As prescribed. As performed."
**Target**: iOS 15+, Swift 5.9+, SwiftUI
**Architecture**: MVVM + Clean Architecture with dependency injection

## Critical Requirements (Non-Negotiable)

See `Specs/SYSTEM_PROMPT.md` for full requirements. Key constraints:

### Timing Accuracy
- Maximum drift: ≤75ms over 30 minutes (screen on)
- Maximum drift: ≤150ms (screen locked)
- Implementation uses `CADisplayLink` for high-precision timing
- Core engine: `Sources/Domain/Engine/TimerEngine.swift`

### Performance
- CPU usage: ≤10% average on A14/A15 devices during 15-minute AMRAP
- Verify via Instruments (see `QA/InstrumentsGuide.md`)
- Energy impact must remain 'low' in Low Power Mode

### Accessibility (WCAG AA)
- Contrast ratio: ≥7:1
- Minimum hit target: 52pt
- Dynamic Type support (must fit at XXXL)
- VoiceOver announcements at key events (see `Specs/EVENTS_TO_CUES.md`)
- UI rules defined in `Specs/UI_RULES.json`

### Background Behavior
- Primary: Background audio mode to keep app active when locked
- Supplementary: Local notifications for key workout events
- Optional: Now Playing integration for lock screen display
- Must handle interruptions (phone calls) and resume at interval boundaries
- See `Specs/BACKGROUND_STRATEGY_iOS15.json` for full implementation details

## Architecture

### Three-Layer Structure

```
Sources/
├── App/           # Application entry point, DI container
├── Domain/        # Business logic, timer engine, models
│   ├── Engine/    # TimerEngine with CADisplayLink
│   └── Models/    # TimerType, state definitions
└── UI/            # SwiftUI views and components
    ├── Screens/   # MainContainerView (active), TimerView, InlineConfigureTimerView
    └── Components/# BigTimeDisplay, controls

Note: HomeView and ConfigureTimerView removed (git history: commit 7221423)
      App now uses MainContainerView with sidebar navigation pattern.
```

### State Machine
States flow: `idle → running → paused → resting → finished`
- Defined in `TimerEngine.State`
- UI layout adapts per state (see `UI_RULES.json` layoutStates)

### Timer Types Configuration
All timer behavior is spec'd in `Specs/TIMER_TYPES.json`:
- Direction (up/down/intervals)
- Events and their audio/haptic/VoiceOver cues
- Counter types (rep, set, round)
- Multi-set support with configurable rest periods

## Testing

### Test Structure
```
Tests/
├── DomainTests/      # Unit tests (TimingDriftTests.swift)
├── UITests/          # UI automation (TimerControlsTests.swift)
└── SnapshotTests/    # Visual regression tests
```

### Quality Assurance
- **Soak Testing**: Follow `QA/SoakTestChecklist.md` for 20-minute validation
- **Drift Testing**: Validate timing accuracy requirements
- **Interruption Testing**: Phone calls, background transitions
- **Accessibility**: VoiceOver, Dynamic Type XXXL, contrast
- **Performance**: CPU profiling with Instruments

### Running Tests
This is a skeleton repository without an Xcode project yet. Once project is created:
- Unit tests: `xcodebuild test -scheme WorkoutTimer -destination 'platform=iOS Simulator,name=iPhone 15'`
- UI tests: Include `-only-testing:WorkoutTimerUITests`
- Use `.xctestplan` when available

## Key Implementation Details

### Timing Engine (`TimerEngine.swift`)
- Uses `CADisplayLink` tied to display refresh for sub-frame accuracy
- Tracks wall-clock time via `Date()` to avoid drift accumulation
- Accumulates elapsed time across pause/resume cycles
- Delegate pattern for tick updates and event emission

### Audio/Haptic Feedback
- Patterns defined in `Resources/Haptics/Patterns.json`
- Mapping in `Specs/EVENTS_TO_CUES.md`:
  - start → rigid haptic
  - warnings → warning haptic
  - finish → success haptic
- Audio files expected: start.caf, tick.caf, warn.caf, beep_1hz.caf, end.caf

### Multi-Set Support
- Rest periods display full-screen countdown
- Option to skip rest between sets
- Summary persists locally with set times and counter timestamps

## Specs Directory

Machine-readable specifications:
- `SYSTEM_PROMPT.md` - Build canon and requirements
- `TIMER_TYPES.json` - Complete timer behavior definitions
- `UI_RULES.json` - Layout, accessibility, theming rules
- `EVENTS_TO_CUES.md` - Audio/haptic/VoiceOver mappings
- `QA_PLAN.md` - Test acceptance criteria
- `QUESTIONS.md` - Open design questions

When making changes, validate against specs first. These define the contract.
