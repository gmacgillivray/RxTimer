# RxTimer

**As prescribed. As performed.**

RxTimer is a precision workout timer for CrossFit athletes, featuring AMRAP, EMOM, and For Time modes with sub-millisecond timing accuracy.

## App Information

- **Name**: RxTimer
- **Subtitle**: CrossFit WOD Timer - Rx Ready
- **Platform**: iOS 15+
- **Architecture**: SwiftUI, MVVM + Clean Architecture
- **Timing Engine**: CADisplayLink with ≤75ms drift over 30 minutes

## Features

- **AMRAP**: Countdown timer with elapsed time tracking and round splits
- **EMOM**: Interval timing with audio/visual cues
- **For Time**: Count-up timer with optional time cap
- **Multi-Set Support**: Configurable rest periods between sets
- **Round Tracking**: Individual split times for performance analysis
- **Background Mode**: Works when screen is locked
- **Accessibility**: Full VoiceOver support, WCAG AA compliant

## Structure
- **Specs/**: Machine-readable specifications & QA plan
- **Sources/**: App, Domain, UI layers (MVVM architecture)
- **Resources/**: Audio/Haptics assets
- **Tests/**: Unit/UI/Snapshot tests
- **QA/**: Soak test & Instruments guides

## Documentation

See `Specs/SYSTEM_PROMPT.md` for technical requirements and `CLAUDE.md` for development guidelines.

## Copyright

Copyright © 2025 RxTimer. All rights reserved.
