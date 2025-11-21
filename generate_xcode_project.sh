#!/bin/bash

# WorkoutTimer Xcode Project Generator
# This script creates a proper Xcode project structure

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="WorkoutTimer"

echo "Generating Xcode project for $PROJECT_NAME..."

# Remove existing project if it exists
rm -rf "$PROJECT_DIR/$PROJECT_NAME.xcodeproj"

# Create Package.swift for SPM (simplest approach to generate Xcode project)
cat > "$PROJECT_DIR/Package.swift" << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WorkoutTimer",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "WorkoutTimer", targets: ["WorkoutTimer"])
    ],
    targets: [
        .target(
            name: "WorkoutTimer",
            path: "Sources"
        )
    ]
)
EOF

# Generate Xcode project from Package
echo "Generating Xcode project from Swift Package..."
swift package generate-xcodeproj

echo "✅ Xcode project generated successfully!"
echo "📂 Open: $PROJECT_DIR/$PROJECT_NAME.xcodeproj"
echo ""
echo "Note: You may need to manually configure:"
echo "  - App target instead of library target"
echo "  - Info.plist path"
echo "  - Asset catalogs"
echo "  - CoreData model"
echo ""
echo "Alternative: Open the project folder in Xcode and create a new iOS App project,"
echo "then add the existing source files from Sources/, Specs/, etc."
EOF

chmod +x "$PROJECT_DIR/generate_xcode_project.sh"
