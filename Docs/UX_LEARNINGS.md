# RxTimer UX Improvement - Learnings

## Patterns That Worked Well

### Shared extracted views for orientation support
Extracting `timeDisplayContent` and `secondaryInfoView` as computed properties lets portrait and landscape layouts reuse identical logic while differing only in layout structure (VStack vs HStack). This avoids code duplication while keeping each layout definition clear and readable.

### Settings gating via coordinator injection
Adding `settings: SettingsManager = .shared` to coordinators rather than checking settings at the ViewModel level keeps the gating logic close to the side effect (audio/haptic playback) and preserves testability. The coordinator is the right abstraction level — it's already the "should I do this thing?" decision point.

### DispatchWorkItem for cancellable timers
Using `DispatchWorkItem` for the undo toast auto-dismiss is cleaner than tracking Timer objects. The `cancel()` method provides clean teardown when a new toast arrives before the old one expires.

### Set-based undo via array operations
`RoundTracker.undoLastRound()` uses `removeLast()` on the array and restores state from the new last element (or defaults if empty). This is simpler than maintaining a parallel undo stack and leverages the rounds array as its own history.

### Optional callbacks for backward compatibility
Making `onRepeat` optional in `WorkoutSummaryView` means existing call sites (like the pending workout summary) can adopt the feature incrementally without breaking.

## Anti-Patterns Avoided

### Not duplicating orientation-specific code
The initial impulse was to have separate VStack-based and HStack-based views with copy-pasted content. Instead, shared components (`timeDisplayContent`) keep the views DRY while `isLandscape` conditionals in size properties handle the dimensional differences.

### Not over-engineering settings
A simple `UserDefaults`-backed `@Published` property pattern is sufficient. No need for a Codable settings struct or CoreData persistence for 3 boolean toggles. The `didSet` pattern keeps persistence automatic and invisible.

### Not adding settings checks everywhere
Rather than sprinkling `if settings.audioEnabled` throughout the ViewModel, the check lives in one place per coordinator. The ViewModel doesn't even know settings exist — it just calls `handleEvent()` as before.
