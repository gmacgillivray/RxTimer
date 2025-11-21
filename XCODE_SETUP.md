# Opening WorkoutTimer in Xcode

The WorkoutTimer application is ready to be opened in Xcode. Follow one of these methods:

## Method 1: Open as Swift Package (Easiest - Modern Xcode)

This project includes a `Package.swift` file that modern Xcode can open directly.

1. **Open in Xcode**:
   ```bash
   open Package.swift
   ```
   Or in Xcode: File → Open → Select this folder

2. **Wait for indexing** to complete (Xcode will parse all Swift files)

3. **Select the WorkoutTimer scheme** in the toolbar

4. **Run limitations**: Swift Packages don't support all iOS features by default. You'll need to convert to a full App project for:
   - Info.plist configuration
   - Background Modes
   - Asset Catalogs
   - Core Data models in app bundle

## Method 2: Create Full Xcode Project (Recommended for Production)

For full iOS app features, create a proper Xcode project:

### Step-by-Step Instructions

1. **Open Xcode**

2. **Create New Project**:
   - File → New → Project
   - Select **iOS** → **App**
   - Click Next

3. **Configure Project**:
   - Product Name: `WorkoutTimer`
   - Team: (select your team)
   - Organization Identifier: `com.yourcompany` (or your domain)
   - Interface: **SwiftUI** ✓
   - Language: **Swift** ✓
   - Storage: **None** (we have our own Core Data model)
   - Include Tests: ✓ (optional)
   - Click Next

4. **Save Location**:
   - Navigate to: `/Users/geoffreymacgillivray/Programs/Most Final WOD Timer`
   - **Important**: Save it IN this directory (will merge with existing files)
   - Click Create

5. **Clean Up Auto-Generated Files**:
   Delete these auto-generated files from the project navigator:
   - `WorkoutTimerApp.swift` (we have our own in Sources/App/)
   - `ContentView.swift` (we have our own views)
   - Any auto-generated test files
   - Keep: `.xcodeproj`, `Assets.xcassets` if created

6. **Add Existing Source Files**:
   - Right-click on WorkoutTimer group in Project Navigator
   - Add Files to "WorkoutTimer"...
   - Navigate to `Sources` folder
   - Select `Sources` folder
   - Check **"Create groups"**
   - Check target membership for **WorkoutTimer**
   - Click Add
   - Repeat for `Tests` folder

7. **Add Core Data Model**:
   - Drag `Sources/Persistence/WorkoutTimer.xcdatamodeld` into project
   - Ensure it's added to WorkoutTimer target

8. **Configure Info.plist**:
   - In project navigator, select the existing `Info.plist` in project root
   - Or use the one Xcode generated
   - Ensure it contains Background Modes for Audio
   - In Build Settings, set `Info.plist File` to `Info.plist`

9. **Add Capabilities**:
   - Select WorkoutTimer target
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add **Background Modes**
     - Check "Audio, AirPlay, and Picture in Picture"
   - Click "+ Capability" again
   - Add **Push Notifications** (for local notifications)

10. **Configure Build Settings**:
    - Select WorkoutTimer target
    - Build Settings tab
    - Search for "iOS Deployment Target"
    - Set to **iOS 15.0** or later
    - Search for "Swift Language Version"
    - Ensure it's **Swift 5**

11. **Add Assets**:
    - If Xcode didn't create `Assets.xcassets`, add the one from `Resources/`
    - Drag `Resources/Assets.xcassets` into project

12. **Create Audio Files** (Optional for now):
    The app expects these files in a Resource bundle:
    - `silence.m4a` - for background audio
    - `start.caf`, `tick.caf`, `warn.caf`, `beep_1hz.caf`, `end.caf`

    You can add placeholder files later. The app will warn but still function.

## Method 3: Use Provided Package.swift (Quick Test)

For quick testing without full iOS features:

```bash
cd "/Users/geoffreymacgillivray/Programs/Most Final WOD Timer"
open Package.swift
```

Then in Xcode:
- Select "My Mac (Designed for iPhone)" or an iOS Simulator
- Product → Build (⌘B)

**Limitations**: This won't include iOS-specific features like Background Audio, Notifications, etc.

## Verification Steps

After setting up with Method 2, verify your configuration:

### 1. Build the Project
```
⌘B (Product → Build)
```

Should compile without errors. Common issues:
- **Missing WorkoutTimer module**: Ensure all source files are added to target
- **Core Data errors**: Ensure .xcdatamodeld is in Compile Sources
- **Swift version errors**: Check Swift Language Version in Build Settings

### 2. Run Tests
```
⌘U (Product → Test)
```

Should see tests pass in Test Navigator.

### 3. Run on Simulator
```
⌘R (Product → Run)
```

Should launch the app showing:
- Home screen with three timer types
- Tap a timer → Configuration screen
- Configure and Start → Timer screen

### 4. Test Background Audio

1. Start a timer
2. Lock the simulator (Device → Lock, or ⌘L)
3. Swipe up for Control Center
4. Should see "WorkoutTimer" in Now Playing with elapsed time

## Troubleshooting

### "Cannot find 'WorkoutTimer' in scope"

**Solution**: In Build Phases → Compile Sources, ensure all `.swift` files from `Sources/` are listed.

### Core Data Errors

**Solution**:
1. Verify `WorkoutTimer.xcdatamodeld` is in project
2. Check it's listed in Build Phases → Compile Sources
3. Ensure "Code Generation" is set to "Class Definition"

### Background Audio Not Working

**Solution**:
1. Capabilities → Background Modes → Audio is checked
2. Info.plist contains `UIBackgroundModes` array with `audio` string
3. Add `silence.m4a` file to Resources (can be any silent audio file)

### Notifications Not Appearing

**Solution**:
1. Capabilities → Push Notifications is added
2. Run app, grant permission when prompted
3. Check Settings → WorkoutTimer → Notifications are enabled

### Build Errors About Missing Imports

**Solution**: Clean build folder:
```
Product → Clean Build Folder (⇧⌘K)
```
Then rebuild (⌘B)

## Project Structure in Xcode

After setup, your project navigator should show:

```
WorkoutTimer/
├── Sources/
│   ├── App/
│   │   └── WorkoutTimerApp.swift          [App entry point]
│   ├── Domain/
│   │   ├── Engine/
│   │   │   └── TimerEngine.swift          [Core timing logic]
│   │   └── Models/
│   │       ├── TimerType.swift
│   │       ├── TimerConfiguration.swift
│   │       └── TimerState.swift
│   ├── Services/
│   │   ├── BackgroundAudioService.swift   [Background audio]
│   │   ├── NotificationService.swift      [Local notifications]
│   │   ├── HapticService.swift            [Haptic feedback]
│   │   └── AudioService.swift             [Sound effects]
│   ├── Persistence/
│   │   ├── PersistenceController.swift
│   │   └── WorkoutTimer.xcdatamodeld      [Core Data model]
│   └── UI/
│       ├── ViewModels/
│       │   └── TimerViewModel.swift
│       ├── Screens/
│       │   ├── HomeView.swift
│       │   ├── ConfigureTimerView.swift
│       │   └── TimerView.swift
│       └── Components/
│           └── BigTimeDisplay.swift
├── Resources/
│   └── Assets.xcassets/
├── Tests/
│   ├── DomainTests/
│   ├── UITests/
│   └── SnapshotTests/
└── Info.plist
```

## Next Steps

Once the project builds successfully:

1. **Review Specifications**: Read `CLAUDE.md` and `Specs/` folder for requirements
2. **Add Audio Files**: Create or source the required .caf and .m4a files
3. **Run Soak Tests**: Follow `QA/SoakTestChecklist.md`
4. **Profile Performance**: Use Instruments to verify CPU usage ≤10%
5. **Test Accessibility**: Enable VoiceOver, test Dynamic Type

## Getting Help

- See `BUILD_INSTRUCTIONS.md` for detailed configuration steps
- See `CLAUDE.md` for architecture overview
- See `Specs/` directory for complete specifications
- See `QA/` directory for testing guidelines

## Quick Start Command

```bash
# Open in Xcode (will open as Swift Package)
open "/Users/geoffreymacgillivray/Programs/Most Final WOD Timer"

# Or open Package.swift directly
open "/Users/geoffreymacgillivray/Programs/Most Final WOD Timer/Package.swift"
```

For full app features, follow **Method 2** above.
