import AppKit
import ServiceManagement

final class MenuBarController: NSObject {
    private let monitor: ClipboardMonitor
    private var statusItem: NSStatusItem?
    private var launchAtLoginItem: NSMenuItem?

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
    }

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "MSFastCopyStatusItem"
        item.isVisible = true

        if let button = item.button {
            button.title = "MS"
            button.font = NSFont.boldSystemFont(ofSize: 12)
            button.image = Self.statusImage(enabled: monitor.isEnabled)
            button.imagePosition = .imageLeft
            button.toolTip = "MS Fast Copy"
        }

        item.menu = buildMenu()
        statusItem = item
    }

    func refresh() {
        guard let button = statusItem?.button else { return }
        button.title = "MS"
        button.image = Self.statusImage(enabled: monitor.isEnabled)
        launchAtLoginItem?.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let toggle = NSMenuItem(
            title: "启用剪贴板修复",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggle.target = self
        toggle.state = monitor.isEnabled ? .on : .off
        menu.addItem(toggle)

        menu.addItem(.separator())

        let launchItem = NSMenuItem(
            title: "登录时启动",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        launchAtLoginItem = launchItem
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let about = NSMenuItem(
            title: "关于 MS Fast Copy",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        about.target = self
        menu.addItem(about)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "退出",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    @objc private func toggleEnabled() {
        monitor.setEnabled(!monitor.isEnabled)
        statusItem?.menu = buildMenu()
        refresh()
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.isEnabled.toggle()
        refresh()
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private static func statusImage(enabled: Bool) -> NSImage? {
        if let symbol = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "MS Fast Copy") {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            let image = symbol.withSymbolConfiguration(config) ?? symbol
            image.isTemplate = true
            return image
        }
        return nil
    }
}

enum LaunchAtLogin {
    private static let key = "launchAtLogin"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            updateRegistration(enabled: newValue)
        }
    }

    private static func updateRegistration(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // 沙盒外或未签名时可能失败，忽略
            }
        }
    }
}
