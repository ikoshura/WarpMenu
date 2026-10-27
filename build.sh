#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
APP="WarpMenu.app"
IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application: Abrar Zharifan Syah (JSYLVAZ935)}"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -target arm64-apple-macosx14.0 -O -o "$APP/Contents/MacOS/WarpMenu" WarpMenu.swift -framework AppKit -framework ServiceManagement
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
if security find-identity -v -p codesigning 2>/dev/null | grep -qF "$IDENTITY"; then
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
  echo "Signed: $IDENTITY (hardened runtime)"
else
  codesign --force --sign - "$APP"
  echo "Signed ad-hoc (Developer ID cert not found)"
fi
codesign --verify --deep --strict "$APP"
echo "Built: $PWD/$APP"
