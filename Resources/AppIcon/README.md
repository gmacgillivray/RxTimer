# RxTimer App Icon

## Overview

This directory contains the RxTimer app icon design files.

## Design Concept

**Style**: Medical-inspired "Rx" prescription symbol integrated with timer element
**Tagline**: "As prescribed. As performed."

### Visual Elements
- **Rx Symbol**: Bold white "Rx" in sans-serif style (prescription reference)
- **Timer Ring**: Orange gradient circular progress ring (countdown visualization)
- **Background**: Deep blue gradient (#1E3A8A to #1E40AF)
- **Clock Accent**: Minimalist clock hands for subtle timer reference
- **Corner Radius**: 226px (iOS standard for 1024x1024 icons)

### Color Palette
- **Primary**: Deep Blue `#1E3A8A` (Professional, trustworthy)
- **Accent**: White `#FFFFFF` (Clean, high contrast)
- **Highlight**: Orange `#F97316` (Energy, intensity)

## Files

- `RxTimer-Icon.html` - Interactive SVG icon generator (open in browser)
- `README.md` - This file

## How to Generate App Icon

### Method 1: Use the HTML File (Recommended)

1. Open `RxTimer-Icon.html` in a web browser
2. Click the "Download SVG" button to save the SVG file
3. Convert SVG to PNG at 1024x1024px using one of these tools:

**Online Converters:**
- [CloudConvert](https://cloudconvert.com/svg-to-png)
- [SVGtoPNG](https://svgtopng.com/)

**Mac Apps:**
- Sketch
- Figma (free)
- Affinity Designer
- Adobe Illustrator

**Command Line (if you have rsvg-convert):**
```bash
rsvg-convert -w 1024 -h 1024 RxTimer-Icon.svg -o AppIcon-1024.png
```

### Method 2: Screenshot Method

1. Open `RxTimer-Icon.html` in Safari or Chrome
2. Zoom in to make the icon large
3. Take a high-resolution screenshot of just the icon
4. Open in Preview/Photoshop and resize to exactly 1024x1024px
5. Export as PNG

### Method 3: Use Xcode Asset Catalog

Once you have the 1024x1024 PNG:

1. Open Xcode project
2. Navigate to `Assets.xcassets` > `AppIcon`
3. Drag the 1024x1024 PNG into the "App Store iOS" slot
4. Xcode will automatically generate all required sizes

## App Icon Sizes Required (iOS)

Xcode generates these automatically from the 1024x1024 master:

| Size | Usage |
|------|-------|
| 1024x1024 | App Store |
| 180x180 | iPhone @3x |
| 120x120 | iPhone @2x |
| 167x167 | iPad Pro @2x |
| 152x152 | iPad @2x |
| 76x76 | iPad @1x |
| 60x60 | iPhone notifications |
| 40x40 | Spotlight |

## Design Variations

If you want to modify the design, edit the SVG in `RxTimer-Icon.html`:

### Make timer ring more prominent:
Change line 48 opacity from `0.9` to `1.0`

### Bolder Rx symbol:
Change stroke-width from `58` to `65` on lines 58 and 64

### Remove clock accent:
Delete lines 68-78 (the entire `clockAccent` group)

### Different color scheme:
Replace hex colors in the `<defs>` section (lines 11-27)

## Design Philosophy

The RxTimer icon communicates:
- **Medical precision** ("Rx" prescription symbol)
- **CrossFit community** ("Rx" means "as prescribed" in CrossFit)
- **Timing accuracy** (timer ring and clock hands)
- **Premium quality** (clean, professional design)
- **Energy/intensity** (orange accent suggests workout intensity)

The design is minimalist and scalable, ensuring it remains recognizable even at small sizes (like 40x40px in Spotlight).

## Copyright

Copyright © 2025 RxTimer. All rights reserved.
