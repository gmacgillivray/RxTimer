# Building WorkoutTimer in Xcode

## Quick Start

### Option 1: Create Project Manually in Xcode (Recommended)

1. Open Xcode
2. File → New → Project
3. Select "iOS" → "App"
4. Set:
   - Product Name: **WorkoutTimer**
   - Team: Your team
   - Organization Identifier: com.yourcompany
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **Core Data** ✓
   - Include Tests: ✓
5. Save in this directory
6. Delete the generated Source files (keep the .xcodeproj)
7. Add existing files:
   - Right-click project → Add Files to "WorkoutTimer"
   - Select `Sources/` folder → Add
   - Select `Resources/` folder → Add
   - Select `Tests/` folder → Add
8. Configure Build Settings:
   - Select WorkoutTimer target
   - Signing & Capabilities tab
   - Click "+ Capability" → Background Modes
   - Check "Audio, AirPlay, and Picture in Picture"
   - Click "+ Capability" → Push Notifications (for local notifications)
9. Set Info.plist:
   - Select `Info.plist` from root directory in project navigator
   - Set as Custom iOS Target Properties file in Build Settings
10. Add Core Data Model:
    - Drag `Sources/Persistence/WorkoutTimer.xcdatamodeld` into project
11. Build and Run!

### Option 2: Use Provided Script

```bash
cd "/Users/geoffreymacgillivray/Programs/Most Final WOD Timer"
./generate_xcode_project.sh
```

Then open `WorkoutTimer.xcodeproj` and configure as needed.

## Project Structure

```
WorkoutTimer/
├── Sources/
│   ├── App/                    # App entry point
│   ├── Domain/                 # Business logic
│   │   ├── Engine/            # TimerEngine
│   │   └── Models/            # Data models
│   ├── Services/              # Background audio, notifications, etc.
│   ├── Persistence/           # Core Data
│   └── UI/                    # SwiftUI views
│       ├── ViewModels/
│       ├── Screens/
│       └── Components/
├── Resources/                  # Audio files, assets
├── Tests/                      # Unit & UI tests
├── Specs/                      # Machine-readable specifications
└── Info.plist                 # App configuration

```

## Configuration Checklist

- [ ] Bundle Identifier set
- [ ] Team selected for signing
- [ ] Background Modes: Audio enabled
- [ ] Push Notifications capability added
- [ ] Info.plist configured
- [ ] Core Data model linked
- [ ] Deployment target: iOS 15.0+
- [ ] Swift Language Version: 5.9

## Required Audio Files

The app expects these audio files in `Resources/Audio/`:
- `silence.m4a` - Silent audio for background mode
- `start.caf` - Workout start sound
- `tick.caf` - Interval tick sound
- `warn.caf` - Warning sound
- `beep_1hz.caf` - Countdown beep
- `end.caf` - Workout complete sound

You can use placeholder sounds initially or generate them using:
- macOS `afconvert` for .caf files
- Any audio editor for .m4a

## Troubleshooting

### Build Errors

**"Cannot find 'PersistenceController' in scope"**
- Ensure Core Data model is added to target
- Check that `WorkoutTimer.xcdatamodeld` is in Compile Sources

**"Missing audio files"**
- Audio files are optional for initial testing
- The app will print warnings but still function
- Add placeholder files to Resources/Audio/

**"Background audio not working"**
- Check Background Modes capability is enabled
- Verify Info.plist has `UIBackgroundModes` with `audio`

### Runtime Issues

**Timer stops in background**
- Ensure Background Audio capability is enabled
- Check that silence.m4a is properly added to bundle

**Notifications not appearing**
- First run requests permission - tap Allow
- Check Notification settings in Settings app

## Testing

Run tests from Xcode:
- ⌘U - Run all tests
- Or Product → Test

For soak testing, see `QA/SoakTestChecklist.md`

## Next Steps

1. Build and run the app
2. Test each timer type (FT, AMRAP, EMOM)
3. Verify background behavior
4. Run unit tests
5. Profile with Instruments for CPU usage
6. Review specifications in `Specs/` directory

## Support

See `CLAUDE.md` for comprehensive development guide and architecture overview.
