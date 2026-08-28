#!/bin/bash
# USBChime build script — SPM build + app bundle + ad-hoc sign
set -e
cd "$(dirname "$0")"

APP_NAME="USBChime"
APP="$APP_NAME.app"
CONFIG="${1:-release}"

echo "==> Building ($CONFIG)..."
swift build -c "$CONFIG"

echo "==> Bundling $APP..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

BIN=".build/$([ "$CONFIG" = "debug" ] && echo debug || echo release)/$APP_NAME"
cp "$BIN" "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"

# Copy SPM resource bundle (sounds) into the app
RES_BUNDLE=$(find .build -type d -name "$APP_NAME""_""$APP_NAME.bundle" 2>/dev/null | head -1)
if [ -n "$RES_BUNDLE" ]; then
    cp -R "$RES_BUNDLE"/* "$APP/Contents/Resources/"
fi

# App icon
if [ -f "Sources/Resources/AppIcon.icns" ]; then
    cp "Sources/Resources/AppIcon.icns" "$APP/Contents/Resources/"
fi

echo "==> Signing..."
codesign --force --deep --sign - "$APP"

echo "==> Done: $APP"
