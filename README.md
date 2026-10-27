<div align="center">
<img src="AppIcon.iconset/icon_128x128.png" width="128" alt="WarpMenu icon">

# WarpMenu

A tiny replacement menubar for Cloudflare WARP on macOS.
Left-click the shield icon and you get a menu — no window ever opens.

Signed and notarized. No Dock icon, no window, ~100 KB.

</div>

## Features

- Menubar icon reflects tunnel state (filled shield = connected)
- One-click Connect / Disconnect from the menu
- Optional **Single-Click to Toggle** mode: left-click flips the tunnel, right-click opens the menu
- **Open at Login** toggle (system-managed via `SMAppService`)
- Graceful states when WARP isn't installed or the daemon is silent, with a guided download link
- Talks to the official WARP daemon through `warp-cli` — nothing proprietary, no kernel extensions

## Requirements

The official **Cloudflare WARP package** (daemon + `warp-cli`), available at
[1.1.1.1](https://1.1.1.1/). The GUI window itself is **not** required —
WarpMenu replaces it. If WARP isn't installed, the menu shows
`WARP Not Installed` and offers to open the download page.

## Install

1. Download `WarpMenu.dmg` from [Releases](../../releases).
2. Open it and drag `WarpMenu.app` to Applications.
3. Run it. If you quit the official Cloudflare WARP window afterwards, the
   tunnel keeps running under WarpMenu's control.

## Usage

| Menu item              | What it does                                              |
| ---------------------- | --------------------------------------------------------- |
| Connect / Disconnect   | Flips the WARP tunnel (via `warp-cli`)                    |
| Single-Click to Toggle | Left-click toggles, right-click opens the menu (sticky)   |
| Open at Login          | Registers WarpMenu as a login item                        |
| WARP Settings…         | Opens the official WARP window (or the download page)     |

## Build from source

Requires Xcode command line tools (macOS 14+ target).

```sh
./build.sh        # compile + sign with your Developer ID (edit CODESIGN_IDENTITY)
./notarize.sh     # notarize the .app (needs a `WarpMenu` notarytool profile)
./release.sh      # build a signed + notarized WarpMenu.dmg
```

`CODESIGN_IDENTITY` defaults to a specific Developer ID — override it:

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build.sh
```

Store notarization credentials once (password = app-specific password):

```sh
xcrun notarytool store-credentials "WarpMenu" \
  --apple-id "you@icloud.com" --team-id "TEAMID"
```

## Project layout

| File              | Purpose                                              |
| ----------------- | ---------------------------------------------------- |
| `WarpMenu.swift`  | The whole app — AppKit status item + `warp-cli` glue |
| `gen_icon.swift`  | Renders `AppIcon.icns` from code (gradient + glyphs)  |
| `AppIcon.iconset` | Generated icon sources                               |
| `Info.plist`      | Bundle metadata (`LSUIElement` agent, no Dock icon)   |
| `build.sh`        | Compile + Developer ID sign + verify                 |
| `notarize.sh`     | Notarize + staple the `.app`                         |
| `release.sh`      | Build the distributable notarized `.dmg`             |

## Disclaimer

Unofficial community project, not affiliated with Cloudflare, Inc.
The icon is inspired by Cloudflare's 1.1.1.1 branding, which belongs to
Cloudflare. The app requires Cloudflare's official WARP package to function.

## License

MIT — see [LICENSE](LICENSE).
