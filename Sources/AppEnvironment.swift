import AppKit

enum AppEnvironment {
    static var isTranslocated: Bool {
        Bundle.main.bundleURL.path.contains("AppTranslocation")
    }

    /// 若已有实例在运行，激活它并返回 false
    static func acquireSingleInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.msfastcopy.app"
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }

        guard others.isEmpty else {
            others.first?.activate(options: [.activateIgnoringOtherApps])
            return false
        }
        return true
    }

    static func showTranslocationAlert() {
        let alert = NSAlert()
        alert.messageText = "请先将 MS Fast Copy 移到「应用程序」"
        alert.informativeText = """
        当前从下载位置直接运行，macOS 会进入临时隔离模式，可能导致菜单栏图标不显示。

        请先将 MSFastCopy.app 拖到「应用程序」文件夹，再从那里打开。
        """
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }

    static func showStartupHintIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "startupHintShown") else { return }
        UserDefaults.standard.set(true, forKey: "startupHintShown")

        let alert = NSAlert()
        alert.messageText = "MS Fast Copy 已在运行"
        alert.informativeText = """
        请在屏幕右上角菜单栏查找「MS」。

        若看不到：打开「系统设置 → 控制中心 → 菜单栏微调」，确认 MSFastCopy 未被隐藏。

        也可在 Dock 栏找到本应用图标。
        """
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }
}
