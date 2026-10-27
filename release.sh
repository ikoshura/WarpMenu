#!/bin/zsh
# Build a signed + notarized distributable DMG: ./release.sh
# Requires: Developer ID cert (see build.sh) + `WarpMenu` notarytool profile.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh

IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application: Abrar Zharifan Syah (JSYLVAZ935)}"
DMG="WarpMenu.dmg"
STAGE="$(mktemp -d)"

cp -R WarpMenu.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "WarpMenu" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

codesign --force --timestamp --sign "$IDENTITY" "$DMG"
echo "DMG signed."

xcrun notarytool submit "$DMG" --keychain-profile "WarpMenu" --wait
xcrun stapler staple "$DMG"
spctl -a -t open -vv "$DMG"
ls -lh "$DMG"
echo "Release ready: $PWD/$DMG"
