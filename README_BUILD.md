# Build Instructions

## Current Build Issues with Swift Package

The project is currently experiencing build issues when opened as a Swift Package because it contains iOS-specific code (UIKit, AVFoundation features) that aren't available on macOS.

## ✅ **Recommended Solution: Create Xcode iOS App Project**

To properly build and run this application, you need to create a full iOS App project in Xcode:

### Step-by-Step:

1. **Open Xcode**

2. **Create New Project**:
   - File → New → Project
   - Choose: **iOS** → **App**
   - Click Next

3. **Configure**:
   - Product Name: `WorkoutTimer`
   - Team: (select your team)
   - Organization Identifier: `com.yourcompany`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **Core Data** (check the box)
   - Click Next

4. **Save Location**:
   - Navigate to: `/Users/geoffreymacgillivray/Programs/Most Final WOD Timer`
   - Click Create

5. **Delete Auto-Generated Files**:
   In the Project Navigator, delete:
   - `WorkoutTimerApp.swift` (keep the .xcodeproj)
   - `ContentView.swift`
   - Any other auto-generated Swift files
   - Keep the Xcode project file

6. **Add Existing Sources**:
   - Right-click project root in Navigator
   - "Add Files to WorkoutTimer..."
   - Select `Sources` folder
   - Check "Create groups"
   - Check "WorkoutTimer" target
   - Click Add

7. **Add Tests**:
   - Right-click project root
   - "Add Files to WorkoutTimer..."
   - Select `Tests` folder
   - Add to appropriate test targets

8. **Configure Core Data**:
   - Ensure `WorkoutTimer.xcdatamodeld` from `Sources/Persistence/` is added
   - Check it's in "Compile Sources" under Build Phases

9. **Add Capabilities**:
   - Select WorkoutTimer target
   - "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add **Background Modes**
     - Check "Audio, AirPlay, and Picture in Picture"
   - Add **Push Notifications**

10. **Configure Info.plist**:
    - Use the `Info.plist` in the project root
    - Or ensure Xcode's generated one has:
      - `UIBackgroundModes` = `["audio"]`

11. **Set Deployment Target**:
    - Build Settings → iOS Deployment Target → **15.0**

12. **Build & Run**:
    ```
    ⌘B to build
    ⌘R to run
    ```

## Why Not Swift Package?

Swift Packages are great for libraries, but this is a complete iOS application with:
- UIKit dependencies (haptics, UI components)
- AVFoundation iOS-specific features (audio session)
- Core Data with app bundle resources
- Background modes configuration
- Push notifications

These features require a full iOS App target, not just a Swift Package.

## Quick Fix for Package Build (Not Recommended)

If you really want to build as a package for testing, you would need to:

1. Wrap all iOS-specific code in `#if os(iOS)` checks
2. Remove SwiftUI `@main` entry point
3. Make all types public
4. Move Core Data model to Resources properly

But this defeats the purpose - just create the proper Xcode project instead!

## Alternative: Open Folder in Xcode

You can also:
1. Open Xcode
2. File → Open
3. Select the entire `Most Final WOD Timer` folder
4. Xcode will recognize the structure

Then follow steps 9-12 above to configure.

## Next Steps After Project Creation

1. Build and verify no errors
2. Run on Simulator
3. Test each timer mode
4. Add audio files to Resources/Audio/
5. Run tests with ⌘U
6. Profile with Instruments

## Documentation

- `XCODE_SETUP.md` - Detailed setup guide
- `BUILD_INSTRUCTIONS.md` - Configuration details
- `PROJECT_SUMMARY.md` - Architecture overview
- `CLAUDE.md` - Development guide

---

**TL;DR**: Don't use Swift Package. Create iOS App project in Xcode and add existing sources. See XCODE_SETUP.md for full instructions.
