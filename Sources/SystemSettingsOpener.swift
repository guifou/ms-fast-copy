import AppKit
import ApplicationServices

enum SystemSettingsOpener {
    /// 打开「系统设置 → 隐私与安全性」（Gatekeeper「仍要打开」在此页底部）
    @discardableResult
    static func openPrivacyAndSecurity() -> Bool {
        openFirst([
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension",
            "x-apple.systempreferences:com.apple.preference.security",
        ])
    }

    /// 打开「辅助功能」权限页
    @discardableResult
    static func openAccessibility() -> Bool {
        openFirst([
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        ])
    }

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func promptAccessibilityIfNeeded() {
        guard !isAccessibilityTrusted else { return }
        guard !UserDefaults.standard.bool(forKey: "accessibilityPromptShown") else { return }

        UserDefaults.standard.set(true, forKey: "accessibilityPromptShown")

        let alert = NSAlert()
        alert.messageText = "建议授予辅助功能权限"
        alert.informativeText = """
        MS Fast Copy 需要辅助功能权限，以便在按下 ⌘C 时准确识别复制来源（Word / PowerPoint）。

        点击「打开设置」后，在列表中勾选 MSFastCopy 即可。
        """
        alert.addButton(withTitle: "打开设置")
        alert.addButton(withTitle: "稍后")

        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibility()
        }
    }

    private static func openFirst(_ urlStrings: [String]) -> Bool {
        for urlString in urlStrings {
            guard let url = URL(string: urlString) else { continue }
            if NSWorkspace.shared.open(url) {
                return true
            }
        }
        return false
    }
}
