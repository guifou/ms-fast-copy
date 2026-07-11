import AppKit

@main
final class SetupAppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var statusLabel: NSTextField!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if let appURL = locateMainApp() {
            removeQuarantine(from: appURL)
            updateStatus("已找到 MS Fast Copy，请点击下方按钮完成授权。")
        } else {
            updateStatus("未找到 MSFastCopy.app，请确保它与本安装助手在同一文件夹。")
        }
    }

    private func buildWindow() {
        let width: CGFloat = 440
        let height: CGFloat = 320

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "安装 MS Fast Copy"
        window.center()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        let title = NSTextField(labelWithString: "欢迎使用 MS Fast Copy")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.frame = NSRect(x: 32, y: height - 56, width: width - 64, height: 28)
        content.addSubview(title)

        let body = NSTextField(wrappingLabelWithString: """
        首次安装时，macOS 可能提示「无法验证开发者」。

        1. 点击下方按钮打开「隐私与安全性」
        2. 在页面底部找到 MSFastCopy，点击「仍要打开」
        3. 再点击「启动 MS Fast Copy」
        """)
        body.frame = NSRect(x: 32, y: 120, width: width - 64, height: 120)
        content.addSubview(body)

        statusLabel = NSTextField(wrappingLabelWithString: "准备就绪。")
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.frame = NSRect(x: 32, y: 88, width: width - 64, height: 28)
        content.addSubview(statusLabel)

        let privacyButton = NSButton(title: "打开隐私与安全性设置", target: self, action: #selector(openPrivacySettings))
        privacyButton.bezelStyle = .rounded
        privacyButton.frame = NSRect(x: 32, y: 48, width: 180, height: 32)
        content.addSubview(privacyButton)

        let launchButton = NSButton(title: "启动 MS Fast Copy", target: self, action: #selector(launchMainApp))
        launchButton.bezelStyle = .rounded
        launchButton.keyEquivalent = "\r"
        launchButton.frame = NSRect(x: 228, y: 48, width: 180, height: 32)
        content.addSubview(launchButton)

        window.contentView = content
    }

    @objc private func openPrivacySettings() {
        if SystemSettingsOpener.openPrivacyAndSecurity() {
            updateStatus("已打开系统设置，请在底部点击「仍要打开」。")
        } else {
            updateStatus("无法打开系统设置，请手动进入「隐私与安全性」。")
        }
    }

    @objc private func launchMainApp() {
        guard let appURL = locateMainApp() else {
            updateStatus("未找到 MSFastCopy.app。")
            return
        }

        removeQuarantine(from: appURL)

        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error {
                    self?.updateStatus("启动失败：\(error.localizedDescription)")
                } else {
                    self?.updateStatus("已启动 MS Fast Copy，可关闭此窗口。")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NSApp.terminate(nil)
                    }
                }
            }
        }
    }

    private func locateMainApp() -> URL? {
        let candidates = [
            Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("MSFastCopy.app"),
            URL(fileURLWithPath: "/Applications/MSFastCopy.app"),
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func removeQuarantine(from appURL: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-cr", appURL.path]
        try? process.run()
        process.waitUntilExit()
    }

    private func updateStatus(_ text: String) {
        statusLabel.stringValue = text
    }
}
