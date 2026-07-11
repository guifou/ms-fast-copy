import AppKit

final class ClipboardMonitor {
    private(set) var isEnabled = true

    private let pasteboard = NSPasteboard.general
    private let sanitizer = ClipboardSanitizer()

    private var fallbackTimer: Timer?
    private var globalKeyMonitor: Any?
    private var lastSeenChangeCount = 0
    private var isSanitizing = false

    /// ⌘C / ⌘X 按下瞬间记录的前台应用，用于准确判断复制来源
    private var copySourceApp: NSRunningApplication?
    private var copySourceTime: Date?

    private let copySourceTTL: TimeInterval = 1.5
    private let fallbackPollInterval: TimeInterval = 1.0

    func start() {
        lastSeenChangeCount = pasteboard.changeCount
        installCopyKeyMonitor()
        startFallbackTimer()
    }

    func stop() {
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
            self.globalKeyMonitor = nil
        }
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "isEnabled")
    }

    func loadSettings() {
        if UserDefaults.standard.object(forKey: "isEnabled") == nil {
            isEnabled = true
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: "isEnabled")
        }
    }

    private func installCopyKeyMonitor() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            guard event.modifierFlags.contains(.command) else { return }
            let key = event.charactersIgnoringModifiers?.lowercased()
            guard key == "c" || key == "x" else { return }

            DispatchQueue.main.async {
                self.onCopyKeyPressed()
            }
        }
    }

    private func onCopyKeyPressed() {
        copySourceApp = NSWorkspace.shared.frontmostApplication
        copySourceTime = Date()

        // Office 写入剪贴板略有延迟，稍后读取
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.checkClipboard(preferredSource: self?.copySourceApp)
        }
    }

    private func startFallbackTimer() {
        fallbackTimer?.invalidate()
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: fallbackPollInterval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.pollFallback()
            }
        }
        if let fallbackTimer {
            RunLoop.main.add(fallbackTimer, forMode: .common)
        }
    }

    /// 兜底：捕获菜单栏「编辑 → 复制」等非快捷键复制
    private func pollFallback() {
        guard isEnabled else { return }

        let current = pasteboard.changeCount
        guard current != lastSeenChangeCount else { return }

        let source = recentCopySourceApp() ?? NSWorkspace.shared.frontmostApplication
        checkClipboard(preferredSource: source, observedChangeCount: current)
    }

    private func recentCopySourceApp() -> NSRunningApplication? {
        guard let copySourceApp, let copySourceTime else { return nil }
        guard Date().timeIntervalSince(copySourceTime) < copySourceTTL else { return nil }
        return copySourceApp
    }

    private func checkClipboard(
        preferredSource: NSRunningApplication?,
        observedChangeCount: Int? = nil
    ) {
        guard isEnabled, !isSanitizing else { return }

        let current = observedChangeCount ?? pasteboard.changeCount
        guard current != lastSeenChangeCount else { return }

        lastSeenChangeCount = current

        guard sanitizer.shouldSanitize(pasteboard: pasteboard, sourceApp: preferredSource) else {
            return
        }

        isSanitizing = true
        defer { isSanitizing = false }

        if sanitizer.sanitize(pasteboard: pasteboard) {
            lastSeenChangeCount = pasteboard.changeCount
        }
    }
}
