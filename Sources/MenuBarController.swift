import AppKit
import ServiceManagement

@MainActor
final class MenuBarController {
    private let monitor: ClipboardMonitor
    private var statusItem: NSStatusItem?
    private var launchAtLoginItem: NSMenuItem?

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
    }

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = Self.statusImage(enabled: monitor.isEnabled)
        item.button?.imagePosition = .imageLeading
        item.menu = buildMenu()
        statusItem = item
    }

    func refresh() {
        statusItem?.button?.image = Self.statusImage(enabled: monitor.isEnabled)
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

        let privacyItem = NSMenuItem(
            title: "打开隐私与安全性设置…",
            action: #selector(openPrivacySettings),
            keyEquivalent: ""
        )
        privacyItem.target = self
        menu.addItem(privacyItem)

        let accessibilityItem = NSMenuItem(
            title: "打开辅助功能设置…",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        accessibilityItem.target = self
        menu.addItem(accessibilityItem)

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

    @objc private func openPrivacySettings() {
        SystemSettingsOpener.openPrivacyAndSecurity()
    }

    @objc private func openAccessibilitySettings() {
        SystemSettingsOpener.openAccessibility()
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private static func statusImage(enabled: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let clip = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 3), xRadius: 2, yRadius: 2)
            (enabled ? NSColor.labelColor : NSColor.tertiaryLabelColor).setStroke()
            clip.lineWidth = 1.4
            clip.stroke()

            let text = NSBezierPath()
            text.move(to: NSPoint(x: 5, y: 10))
            text.line(to: NSPoint(x: 13, y: 10))
            text.move(to: NSPoint(x: 5, y: 7))
            text.line(to: NSPoint(x: 11, y: 7))
            text.lineWidth = 1.2
            text.stroke()

            if enabled {
                let check = NSBezierPath()
                check.move(to: NSPoint(x: 12, y: 4))
                check.line(to: NSPoint(x: 14, y: 2))
                check.line(to: NSPoint(x: 16, y: 6))
                NSColor.systemGreen.setStroke()
                check.lineWidth = 1.3
                check.stroke()
            }

            return true
        }
        image.isTemplate = true
        return image
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
