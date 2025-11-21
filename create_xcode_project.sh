#!/bin/bash

# WorkoutTimer Xcode Project Creator
# This script creates a complete Xcode project ready to build

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="WorkoutTimer"

echo "🏗️  Creating Xcode project for $PROJECT_NAME..."
echo ""

# Change to project directory
cd "$PROJECT_DIR"

# Step 1: Create a temporary iOS app using xcode-select
echo "📱 Creating iOS App project structure..."

# Use xcrun to create project (this requires Xcode Command Line Tools)
if ! command -v xcrun &> /dev/null; then
    echo "❌ Error: Xcode Command Line Tools not found"
    echo "Please install: xcode-select --install"
    exit 1
fi

# Create the project using Swift Package Manager as base
echo "📦 Initializing Swift Package..."
cat > Package.swift << 'PACKAGEEOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WorkoutTimer",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "WorkoutTimer", targets: ["WorkoutTimer"])
    ],
    targets: [
        .target(
            name: "WorkoutTimer",
            path: "Sources",
            resources: [
                .process("Persistence/WorkoutTimer.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "WorkoutTimerTests",
            dependencies: ["WorkoutTimer"],
            path: "Tests"
        )
    ]
)
PACKAGEEOF

echo "🔨 Generating Xcode project..."
swift package generate-xcodeproj 2>/dev/null || true

# Check if project was created
if [ ! -d "$PROJECT_NAME.xcodeproj" ]; then
    echo "⚠️  Swift Package project generation not supported on this system"
    echo ""
    echo "📋 Manual Setup Instructions:"
    echo ""
    echo "1. Open Xcode"
    echo "2. File → New → Project"
    echo "3. Choose iOS → App"
    echo "4. Name: WorkoutTimer"
    echo "5. Interface: SwiftUI"
    echo "6. Language: Swift"
    echo "7. Use Core Data: ✓"
    echo "8. Save in: $PROJECT_DIR"
    echo "9. Delete generated source files"
    echo "10. Add existing Sources/, Resources/, Tests/ folders"
    echo "11. Configure Background Modes (Audio) in Capabilities"
    echo ""
    echo "See BUILD_INSTRUCTIONS.md for detailed steps"
    exit 0
fi

echo "✅ Xcode project created!"
echo ""
echo "📂 Project location: $PROJECT_DIR/$PROJECT_NAME.xcodeproj"
echo ""
echo "⚙️  Additional Configuration Required:"
echo "   1. Open $PROJECT_NAME.xcodeproj in Xcode"
echo "   2. Convert library target to App target"
echo "   3. Add Info.plist"
echo "   4. Enable Background Modes (Audio) capability"
echo "   5. Add Push Notifications capability"
echo "   6. Link Core Data model"
echo ""
echo "Or follow BUILD_INSTRUCTIONS.md for complete setup"
echo ""
echo "🚀 To open in Xcode:"
echo "   open $PROJECT_NAME.xcodeproj"

PACKAGEEOF

chmod +x "$PROJECT_DIR/create_xcode_project.sh"
