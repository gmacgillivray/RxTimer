# Removed Files

This document tracks intentionally removed files from the codebase to prevent confusion.

## Removed: 2025-11-20

### HomeView.swift (169 lines)
**Location**: `Sources/UI/Screens/HomeView.swift`
**Reason**: Replaced by `MainContainerView` with sidebar navigation
**Git History**: See commit before removal for file contents
**Status**: Completely unused, zero runtime references

**Description**: Card-based home screen with modal sheet navigation. This was the original navigation pattern but was superseded by `MainContainerView` which provides a master-detail layout with sidebar (see `INTEGRATED_LAYOUT_UPDATE.md`).

### ConfigureTimerView.swift (194 lines)
**Location**: `Sources/UI/Screens/ConfigureTimerView.swift`
**Reason**: Replaced by `InlineConfigureTimerView`
**Git History**: See commit before removal for file contents
**Status**: Completely unused, zero runtime references

**Description**: Modal configuration sheet view. This was replaced by `InlineConfigureTimerView` which displays configuration inline in the content pane of `MainContainerView` rather than as a modal.

## Current Navigation Architecture

**Active**: `MainContainerView` → `InlineConfigureTimerView` → `TimerView` → `WorkoutSummaryView`

The app now uses a sidebar navigation pattern (master-detail) which provides:
- Better iPad experience
- Clearer navigation hierarchy
- State management via `AppNavigationState` enum
- Inline configuration instead of modal sheets

## References

- `INTEGRATED_LAYOUT_UPDATE.md` - Documentation of navigation refactor
- `MainContainerView.swift` - Current active navigation container
- `InlineConfigureTimerView.swift` - Replacement for ConfigureTimerView
- `CLAUDE.md` - Updated architecture documentation

## Future Considerations

If you need to reference the removed files:
1. Use `git log -- Sources/UI/Screens/HomeView.swift` to find removal commit
2. Use `git show COMMIT_HASH:Sources/UI/Screens/HomeView.swift` to view contents
3. Use `git checkout COMMIT_HASH -- Sources/UI/Screens/HomeView.swift` to restore (if needed)

**Note**: These files were intentionally removed to reduce code complexity and maintenance burden. Restoration should only occur if there's a specific need for the original navigation pattern.
