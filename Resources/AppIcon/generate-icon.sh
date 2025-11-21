#!/bin/bash

# RxTimer Icon Generator Script
# This script generates the app icon PNG from the SVG source

set -e

echo "🎨 RxTimer Icon Generator"
echo "=========================="
echo ""

# Check if we're in the right directory
if [ ! -f "RxTimer-Icon.html" ]; then
    echo "❌ Error: RxTimer-Icon.html not found"
    echo "Please run this script from the Resources/AppIcon directory"
    exit 1
fi

# Extract SVG from HTML and save it
echo "📄 Extracting SVG from HTML..."
SVG_FILE="RxTimer-Icon.svg"

# Extract just the SVG content (between <svg> and </svg> tags including the tags)
sed -n '/<svg/,/<\/svg>/p' RxTimer-Icon.html > "$SVG_FILE"

if [ ! -f "$SVG_FILE" ]; then
    echo "❌ Error: Failed to extract SVG"
    exit 1
fi

echo "✅ SVG extracted to $SVG_FILE"
echo ""

# Try to convert SVG to PNG using available tools
OUTPUT_FILE="AppIcon-1024.png"

# Method 1: Try rsvg-convert (librsvg)
if command -v rsvg-convert &> /dev/null; then
    echo "🔄 Converting to PNG using rsvg-convert..."
    rsvg-convert -w 1024 -h 1024 "$SVG_FILE" -o "$OUTPUT_FILE"
    echo "✅ Success! Icon saved as $OUTPUT_FILE"
    exit 0
fi

# Method 2: Try ImageMagick convert
if command -v convert &> /dev/null; then
    echo "🔄 Converting to PNG using ImageMagick..."
    convert -background none -size 1024x1024 "$SVG_FILE" "$OUTPUT_FILE"
    echo "✅ Success! Icon saved as $OUTPUT_FILE"
    exit 0
fi

# Method 3: Try qlmanage (macOS Quick Look)
if command -v qlmanage &> /dev/null && [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🔄 Generating preview using macOS Quick Look..."
    qlmanage -t -s 1024 -o . "$SVG_FILE"
    # qlmanage creates a .png file, rename it
    if [ -f "RxTimer-Icon.svg.png" ]; then
        mv "RxTimer-Icon.svg.png" "$OUTPUT_FILE"
        echo "✅ Success! Icon saved as $OUTPUT_FILE"
        exit 0
    fi
fi

# If we get here, no conversion tool was found
echo "⚠️  No SVG conversion tool found!"
echo ""
echo "The SVG file has been created at: $SVG_FILE"
echo ""
echo "To convert to PNG, install one of these tools:"
echo ""
echo "  Option 1 (Recommended): Install librsvg"
echo "    brew install librsvg"
echo ""
echo "  Option 2: Install ImageMagick"
echo "    brew install imagemagick"
echo ""
echo "  Option 3: Use an online converter"
echo "    Upload $SVG_FILE to https://cloudconvert.com/svg-to-png"
echo "    Set output size to 1024x1024"
echo ""
echo "  Option 4: Open RxTimer-Icon.html in a browser"
echo "    Click 'Download SVG' and use a design tool to export"
echo ""

exit 1
