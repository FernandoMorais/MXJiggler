import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = Settings()
    private lazy var jiggler = JigglerController(settings: settings)
    private var statusItem: NSStatusItem!
    private var contextMenu = NSMenu()
    private var isEnabled = false
    private var ready = false
    private var queuedCommands: [URLCommand] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusButtonClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        jiggler.onPermissionLost = { [weak self] in
            self?.setEnabled(false)
            self?.statusItem.button?.toolTip = "Accessibility permission was removed. Right-click to check permission."
        }
        // Restore only when authorized, without prompting on every launch.
        isEnabled = settings.enabled && AXIsProcessTrusted()
        if isEnabled { jiggler.start() }
        ready = true
        updateUI()
        for command in queuedCommands { execute(command) }
        queuedCommands.removeAll()
    }
    func applicationWillTerminate(_ notification: Notification) { jiggler.stop() }
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard let command = URLCommand(url: url) else { continue }
            if ready { execute(command) } else { queuedCommands.append(command) }
        }
    }
    private func execute(_ command: URLCommand) {
        switch command {
        case .toggle: setEnabled(!isEnabled)
        case .on: setEnabled(true)
        case .off: setEnabled(false)
        }
    }
    @objc private func statusButtonClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            rebuildMenu()
            // Attach only while displaying: a permanent menu consumes left clicks.
            statusItem.menu = contextMenu
            statusItem.button?.performClick(nil)
        } else { setEnabled(!isEnabled) }
    }
    func menuDidClose(_ menu: NSMenu) { statusItem.menu = nil }
    private func setEnabled(_ enabled: Bool) {
        if enabled && !AXIsProcessTrusted() {
            explainPermission(requestPrompt: false)
            return
        }
        guard enabled != isEnabled else {
            settings.enabled = enabled
            return
        }
        isEnabled = enabled
        settings.enabled = enabled
        if enabled { jiggler.start() } else { jiggler.stop() }
        updateUI()
    }
    private func updateUI() {
        let image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "MX Jiggler")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.title = isEnabled ? " ON" : " OFF"
        statusItem.button?.toolTip = isEnabled
            ? "MX Jiggler enabled; waiting for the configured inactivity period."
            : "MX Jiggler off. Left-click to enable; right-click for settings."
    }
    private func item(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }
    private func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(item(isEnabled ? "Turn Jiggler Off" : "Turn Jiggler On", action: #selector(toggle)))
        menu.addItem(.separator())
        let intervalMenu = NSMenu()
        for seconds in Settings.intervals {
            let entry = item("\(Int(seconds)) seconds", action: #selector(setInterval(_:)))
            entry.representedObject = seconds
            entry.state = settings.interval == seconds ? .on : .off
            intervalMenu.addItem(entry)
        }
        let interval = NSMenuItem(title: "Interval", action: nil, keyEquivalent: "")
        interval.submenu = intervalMenu
        menu.addItem(interval)
        let idleMenu = NSMenu()
        for seconds in Settings.idleThresholds {
            let minutes = Int(seconds / 60)
            let title = seconds == 0 ? "Always (no idle threshold)" : "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
            let entry = item(title, action: #selector(setIdleThreshold(_:)))
            entry.representedObject = seconds
            entry.state = settings.idleThreshold == seconds ? .on : .off
            idleMenu.addItem(entry)
        }
        let idle = NSMenuItem(title: "Only Jiggle After", action: nil, keyEquivalent: "")
        idle.submenu = idleMenu
        menu.addItem(idle)
        menu.addItem(item("Check Accessibility Permission", action: #selector(checkAccessibility)))
        menu.addItem(.separator())
        menu.addItem(item("About MX Jiggler", action: #selector(about)))
        let quit = item("Quit MX Jiggler", action: #selector(quit))
        quit.keyEquivalent = "q"
        menu.addItem(quit)
        contextMenu = menu
    }
    @objc private func toggle() { setEnabled(!isEnabled) }
    @objc private func setInterval(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? TimeInterval else { return }
        settings.interval = value
        if isEnabled { jiggler.start() }
    }
    @objc private func setIdleThreshold(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? TimeInterval else { return }
        settings.idleThreshold = value
        if isEnabled { jiggler.start() }
    }
    @objc private func checkAccessibility() {
        if AXIsProcessTrusted() {
            showAlert(title: "Accessibility is enabled", message: "MX Jiggler can move the cursor. Left-click the menu bar item to turn it on.")
        } else { explainPermission(requestPrompt: true) }
    }
    private func explainPermission(requestPrompt: Bool) {
        if requestPrompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
        let alert = NSAlert()
        alert.messageText = "Allow MX Jiggler to move the cursor"
        alert.informativeText = "Enable MX Jiggler in System Settings → Privacy & Security → Accessibility, then turn the jiggler on again. If it is missing, add this app using the + button."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    @objc private func about() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        showAlert(title: "MX Jiggler \(version)", message: "A native menu bar mouse jiggler. Runs locally without telemetry or network requests.")
    }
    @objc private func quit() { NSApp.terminate(nil) }
}
