#!/bin/zsh
# Notarize + staple WarpMenu.app.
# One-time setup (password = app-specific password from appleid.apple.com):
#   xcrun notarytool store-credentials "WarpMenu" \
#     --apple-id "you@icloud.com" --team-id "JSYLVAZ935"
# Then run: ./notarize.sh
set -euo pipefail
cd "$(dirname "$0")"
rm -f WarpMenu.zip
ditto -c -k --keepParent WarpMenu.app WarpMenu.zip
xcrun notarytool submit WarpMenu.zip --keychain-profile "WarpMenu" --wait
xcrun stapler staple WarpMenu.app
spctl -a -t exec -vv WarpMenu.app
echo "Notarized + stapled."
