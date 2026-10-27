import AppKit
import ServiceManagement

let warpApp = "/Applications/Cloudflare WARP.app"
let warpCLICandidates = [
    "/usr/local/bin/warp-cli",
    "/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli",
]
let warpDownloadURL = URL(string: "https://1.1.1.1/")!

func findWarpCLI() -> String? {
    for p in warpCLICandidates where FileManager.default.isExecutableFile(atPath: p) {
        return p
    }
    return nil
}

func guiInstalled() -> Bool {
    FileManager.default.fileExists(atPath: warpApp)
}

func runWarp(_ cli: String, _ args: [String]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: cli)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = Pipe()
    do {
        try p.run()
    } catch {
        return ""
    }
    p.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

enum WarpHealth {
    case ready(connected: Bool)
    case notInstalled   // no warp-cli: official package missing
    case notResponding   // cli present but daemon silent
}

func warpHealth() -> WarpHealth {
    guard let cli = findWarpCLI() else { return .notInstalled }
    let out = runWarp(cli, ["status"])
    let lines = out.components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    guard let first = lines.first?.lowercased() else { return .notResponding }
    // NOTE: check "disconnect" BEFORE "connect" — "Disconnected" contains "Connected"
    if first.contains("disconnect") {
        return .ready(connected: false)
    } else if first.contains("connect") {
        return .ready(connected: true)
    } else {
        return .notResponding
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var item: NSStatusItem!
    var menu: NSMenu!
    var statusLine: NSMenuItem!
    var toggleItem: NSMenuItem!
    var clickModeItem: NSMenuItem!
    var loginItem: NSMenuItem!
    var actionItem: NSMenuItem!
    var isConnected = false
    var timer: Timer?
    let clickKey = "ClickToToggle"

    var clickToToggle: Bool {
        get { UserDefaults.standard.bool(forKey: clickKey) }
        set { UserDefaults.standard.set(newValue, forKey: clickKey) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.isVisible = true

        menu = NSMenu()
        menu.delegate = self
        statusLine = NSMenuItem(title: "Checking…", action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        toggleItem = NSMenuItem(title: "Connect", action: #selector(toggle), keyEquivalent: "")
        toggleItem.target = self
        clickModeItem = NSMenuItem(title: "Single-Click to Toggle", action: #selector(toggleClickMode), keyEquivalent: "")
        clickModeItem.target = self
        loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginItem.target = self
        actionItem = NSMenuItem(title: "WARP Settings…", action: #selector(openActionItem), keyEquivalent: "")
        actionItem.target = self
        let quitItem = NSMenuItem(title: "Quit WarpMenu", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        menu.addItem(statusLine)
        menu.addItem(toggleItem)
        menu.addItem(clickModeItem)
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(actionItem)
        menu.addItem(quitItem)
        syncLoginState()
        configureClickBehavior()

        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func configureClickBehavior() {
        clickModeItem.state = clickToToggle ? .on : .off
        if clickToToggle {
            // Left-click toggles, right-click shows the menu
            item.menu = nil
            if let button = item.button {
                button.target = self
                button.action = #selector(iconClicked(_:))
                button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            }
        } else {
            // Click (left or right) shows the menu
            if let button = item.button {
                button.target = nil
                button.action = nil
            }
            item.menu = menu
        }
    }

    @objc func iconClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        let isRight = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if isRight {
            item.popUpMenu(menu)
        } else {
            toggle()
        }
    }

    @objc func toggleClickMode() {
        clickToToggle.toggle()
        configureClickBehavior()
    }

    func syncLoginState() {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            fputs("Login item error: \(error)\n", stderr)
        }
        syncLoginState()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
        syncLoginState()
    }

    func refresh() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let health = warpHealth()
            let hasGUI = guiInstalled()
            DispatchQueue.main.async {
                guard let self else { return }
                switch health {
                case .ready(let connected):
                    self.isConnected = connected
                    let detail = connected ? "Connected" : "Disconnected"
                    self.statusLine.title = detail
                    self.toggleItem.title = connected ? "Disconnect" : "Connect"
                    self.toggleItem.isEnabled = true
                    self.actionItem.title = hasGUI ? "WARP Settings…" : "Get Cloudflare WARP…"
                    self.setIcon(connected: connected, tooltip: detail)
                case .notInstalled:
                    self.isConnected = false
                    self.statusLine.title = "WARP Not Installed"
                    self.toggleItem.title = "Connect"
                    self.toggleItem.isEnabled = false
                    self.actionItem.title = "Get Cloudflare WARP…"
                    self.setIcon(connected: false, tooltip: "WARP Not Installed")
                case .notResponding:
                    self.isConnected = false
                    self.statusLine.title = "WARP Not Responding"
                    self.toggleItem.title = "Connect"
                    self.toggleItem.isEnabled = false
                    self.actionItem.title = hasGUI ? "WARP Settings…" : "Get Cloudflare WARP…"
                    self.setIcon(connected: false, tooltip: "WARP Not Responding")
                }
            }
        }
    }

    func setIcon(connected: Bool, tooltip: String) {
        guard let button = self.item.button else { return }
        let symbol = connected ? "shield.fill" : "shield"
        if let img = NSImage(systemSymbolName: symbol, accessibilityDescription: "WARP") {
            img.isTemplate = true
            button.image = img
        } else {
            button.title = connected ? "WARP ●" : "WARP ○"
            button.image = nil
        }
        button.toolTip = tooltip
    }

    @objc func toggle() {
        guard let cli = findWarpCLI() else { return }
        let args = isConnected ? ["disconnect"] : ["connect"]
        DispatchQueue.global(qos: .utility).async { [weak self] in
            _ = runWarp(cli, args)
            Thread.sleep(forTimeInterval: 1.0)
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
        }
    }

    @objc func openActionItem() {
        if guiInstalled() {
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: warpApp),
                configuration: NSWorkspace.OpenConfiguration(),
                completionHandler: nil
            )
        } else {
            NSWorkspace.shared.open(warpDownloadURL)
        }
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
