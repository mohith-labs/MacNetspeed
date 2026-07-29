#!/bin/bash
# Build script for NetSpeed menu bar app
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/build/NetSpeed.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🔨 Building NetSpeed (Release)..."
cd "$SCRIPT_DIR"
swift build -c release

echo "📦 Creating app bundle..."
mkdir -p "$MACOS" "$RESOURCES"
cp ".build/release/NetSpeed" "$MACOS/NetSpeed"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
cp "Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
echo -n "APPL????" > "$CONTENTS/PkgInfo"
chmod +x "$MACOS/NetSpeed"

SIZE=$(du -sh "$APP_DIR" | cut -f1)
echo "✅ Build complete! App size: $SIZE"
echo "📍 Location: $APP_DIR"
echo ""
echo "To install: cp -r \"$APP_DIR\" /Applications/"
echo "To run:     open \"$APP_DIR\""
