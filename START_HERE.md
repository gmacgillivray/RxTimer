# 🏁 START HERE - WorkoutTimer Setup

## ⚠️ IMPORTANT: Do Not Open Package.swift Directly

This project contains iOS-specific code that cannot be built as a Swift Package alone.

## ✅ How to Open and Build

### Method 1: Create New Xcode iOS App Project (Recommended)

**Quick Steps:**
1. Open Xcode
2. File → New → Project → iOS → App
3. Name: `WorkoutTimer`
4. Interface: SwiftUI, Language: Swift, Storage: Core Data
5. **Save in THIS directory** (it will merge with existing files)
6. Delete auto-generated source files (keep .xcodeproj)
7. Right-click project → Add Files → Select `Sources` folder
8. Add Background Modes capability (Audio)
9. Build & Run (⌘R)

**Full Instructions**: See `XCODE_SETUP.md`

### Method 2: Open Folder in Xcode

1. Open Xcode
2. File → Open → Select this entire folder
3. Configure as iOS App (not Package)
4. Follow steps 8-9 from Method 1

## 📱 What This App Does

CrossFit-style workout timer with three modes:
- **For Time**: Count up with optional time cap
- **AMRAP**: Count down timer with warnings
- **EMOM**: Interval-based training

Features:
- Multi-set workouts with rest periods
- Rep/round counters
- Background audio to keep timer running when locked
- Local notifications for workout events
- Core Data workout history
- Full accessibility support

## 📚 Documentation

| File | Purpose |
|------|---------|
| **START_HERE.md** | This file - quick start guide |
| **XCODE_SETUP.md** | Complete Xcode setup instructions |
| **README_BUILD.md** | Why Package.swift doesn't work |
| **PROJECT_SUMMARY.md** | Architecture and implementation overview |
| **CLAUDE.md** | AI development guide |
| **BUILD_INSTRUCTIONS.md** | Detailed build configuration |

## 🚀 After Project Setup

1. **Build** - Should compile without errors
2. **Run on Simulator** - Test all three timer modes
3. **Add Audio Files** (optional):
   - Place in `Resources/Audio/`
   - Files: silence.m4a, start.caf, tick.caf, warn.caf, beep_1hz.caf, end.caf
4. **Test Background** - Start timer, lock device, check Now Playing
5. **Run Tests** - ⌘U to run unit tests

## ❓ Troubleshooting

**"Cannot find module"** errors:
- Make sure you created an iOS App project, not opened Package.swift
- Verify all Sources files are added to WorkoutTimer target

**Build errors about availability**:
- Check iOS Deployment Target is set to 15.0+
- Ensure you're building for iOS, not macOS

**Background audio not working**:
- Add Background Modes capability with Audio checked
- Add silence.m4a file to Resources

## 📖 Learn More

- **Specifications**: See `Specs/` directory for complete requirements
- **Testing**: See `QA/` directory for test procedures
- **Architecture**: See `CLAUDE.md` for code structure

---

**Next Step**: Open `XCODE_SETUP.md` and follow the instructions to create your Xcode project.
