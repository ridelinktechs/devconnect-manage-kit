#!/bin/bash
set -e

echo "🔨 Building DevConnect Manage Tool for macOS..."

flutter build macos --release

APP_PATH="build/macos/Build/Products/Release/DevConnect.app"
OUTPUT_DIR="dist/macos"
FINAL_APP="DevConnect Manage Tool.app"
mkdir -p "$OUTPUT_DIR"

# Copy .app bundle, renaming to the full user-facing name so Spotlight /
# Launchpad surface it as "DevConnect Manage Tool". CFBundleDisplayName in
# Info.plist already carries the same name for in-app UI.
rm -rf "$OUTPUT_DIR/$FINAL_APP"
cp -R "$APP_PATH" "$OUTPUT_DIR/$FINAL_APP"

# Create DMG
echo "📦 Creating DMG..."
DMG_NAME="DevConnect-macOS-v1.0.1.dmg"
hdiutil create -volname "DevConnect Manage Tool" \
  -srcfolder "$OUTPUT_DIR/$FINAL_APP" \
  -ov -format UDZO \
  "$OUTPUT_DIR/$DMG_NAME"

echo "✅ Built: $OUTPUT_DIR/$DMG_NAME"
echo "✅ App:   $OUTPUT_DIR/$FINAL_APP"
