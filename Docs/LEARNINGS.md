# RxTimer Architecture Improvement - Learnings

## Patterns That Worked Well

### Set-based flag tracking
Replacing individual boolean flags (e.g., `emomCountdown3Emitted`, `emomCountdown2Emitted`, `emomCountdown1Emitted`) with a single `Set<Int>` and using `set.insert(value).inserted` as a combined check-and-mark operation. This reduces the reset surface area and makes the pattern extensible (e.g., adding countdown at 5 seconds requires zero code changes to the tracking mechanism).

### Thin delegation to extracted classes
When extracting `RoundTracker` and `DisplayThrottler`, the ViewModel retains `@Published` properties that sync from the extracted class. This preserves SwiftUI reactivity while moving logic out. The key insight: the ViewModel becomes a coordinator, not an implementer.

### Constructor injection with defaults
Using `init(service: ServiceType = .shared)` preserves the ergonomics of singleton access for production code while enabling test injection. No existing call sites need to change.

### Single navigation state enum
A single `@State navState: AppNavigationState` with associated values eliminates entire categories of bugs: impossible state combinations, stale state from forgotten cleanup, timing issues between multiple state variables.

## Anti-Patterns Avoided

### Over-extracting
Not every piece of code benefits from extraction. The remaining ~650 lines in TimerView are all tightly coupled view-specific code (layout properties, control button configurations) that wouldn't meaningfully benefit from further splitting.

### Breaking the Combine save chain
When removing the autosave timer, it was important to verify that all meaningful save points were already covered by event-driven saves (state transitions, background notification, round completion). The periodic timer was redundant, not essential.

## Architecture Notes

### File organization
- **Domain layer** (`Sources/Domain/`): Pure logic, no UIKit/SwiftUI imports. `TimerEngine`, `RoundTracker`, models.
- **UI layer** (`Sources/UI/`): Views, ViewModels, utilities. `TimeFormatter` and `DisplayThrottler` live here since they serve UI concerns.
- **Services** (`Sources/Services/`): Coordinators bridge between domain events and system services.

### Testing surface area
The extracted classes (`RoundTracker`, `DisplayThrottler`, `TimeFormatter`) are all independently unit-testable without any UI framework dependencies. The dependency injection in Rec 9 enables mocking coordinators and services in ViewModel tests.
