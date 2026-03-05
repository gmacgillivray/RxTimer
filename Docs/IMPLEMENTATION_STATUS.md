# RxTimer Architecture Improvement - Implementation Status

| # | Recommendation | Status | Notes |
|---|---------------|--------|-------|
| 1 | Deduplicate `formatTime` | Done | Created `TimeFormatter` enum in `Sources/UI/Utilities/TimeFormatter.swift` |
| 2 | Replace boolean flag sprawl in TimerEngine | Done | 9 booleans → 3 Sets (`emomEmittedSeconds`, `restEmittedSeconds`, `amrapEmittedWarnings`) |
| 3 | Fix dead code in `skipRest()` | Done | `skipRest()` reduced to 4 lines |
| 4 | Extract RoundTracker from TimerViewModel | Done | New `Sources/Domain/RoundTracker.swift` (~85 lines) |
| 5 | Extract DisplayThrottler from TimerViewModel | Done | New `Sources/UI/Utilities/DisplayThrottler.swift` (~30 lines) |
| 6 | Consolidate navigation state | Done | Single `@State navState: AppNavigationState` drives all navigation. No `asyncAfter` hacks. |
| 7 | Extract sub-views from TimerView | Done | InfoPill, RoundedCornerShape, PacingStatsView extracted. SlideToFinishButton deduplicated. |
| 8 | Simplify TimerSelectionView init | Done | Init reduced from 6 params to 3 callbacks. State internalized. |
| 9 | Inject services instead of singletons | Done | AudioCoordinator, HapticCoordinator, WorkoutStateManager all injectable with `.shared` defaults |
| 10 | Simplify autosave strategy | Done | Removed periodic `autosaveTimer`. Saves on state transitions, background, and round completion only. |

## Line Count Impact

| File | Before | After | Delta |
|------|--------|-------|-------|
| `TimerViewModel.swift` | 546 | 416 | -130 (-24%) |
| `TimerView.swift` | 942 | 649 | -293 (-31%) |
| `TimerEngine.swift` | 521 | 478 | -43 (-8%) |
| `MainContainerView.swift` | 134 | 91 | -43 (-32%) |

## New Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `Sources/UI/Utilities/TimeFormatter.swift` | 72 | Centralized time formatting |
| `Sources/UI/Utilities/DisplayThrottler.swift` | 32 | Display update throttling |
| `Sources/Domain/RoundTracker.swift` | 85 | Round tracking logic |
| `Sources/UI/Components/InfoPill.swift` | 25 | Extracted component |
| `Sources/UI/Components/RoundedCornerShape.swift` | 15 | Extracted shape |
| `Sources/UI/Components/PacingStatsView.swift` | 80 | Extracted pacing stats |
