import AppKit

/// 检测并清理 Microsoft Office 复制文字时附带的图片格式，
/// 使目标应用（如 Cursor、Codex）粘贴时优先获得纯文本。
final class ClipboardSanitizer {
    private static let imageTypes: Set<String> = [
        "public.tiff",
        "public.png",
        "public.jpeg",
        "com.compuserve.gif",
        "public.pdf",
        "Apple PDF pasteboard type",
        "NSPDFPboardType",
        "NSTIFFPboardType",
        "NeXT TIFF v4.0 pasteboard type",
        "com.apple.pict",
    ]

    private static let imagePrefixes: [String] = [
        "com.microsoft.office.opaque",
        "com.microsoft.office.art",
        "com.microsoft.office.drawing",
        "com.microsoft.office.ole",
        "com.microsoft.Object Link",
        "com.microsoft.DataObject",
    ]

    private static let officeBundleIDs: Set<String> = [
        "com.microsoft.Word",
        "com.microsoft.Powerpoint",
        "com.microsoft.Excel",
        "com.microsoft.Outlook",
    ]

    func shouldSanitize(pasteboard: NSPasteboard, sourceApp: NSRunningApplication?) -> Bool {
        guard let types = pasteboard.types, !types.isEmpty else {
            return false
        }

        let typeStrings = Set(types.map(\.rawValue))
        guard let plainText = extractPlainText(pasteboard: pasteboard), !plainText.isEmpty else {
            return false
        }

        let fromOffice = isFromMicrosoftOffice(sourceApp)
        let hasMSTypes = hasMicrosoftClipboardTypes(typeStrings: typeStrings)
        guard fromOffice || hasMSTypes else {
            return false
        }

        let hasImageTypes = hasImageRepresentation(typeStrings: typeStrings)
        let nsImageReadable = NSImage(pasteboard: pasteboard) != nil
        let hasRichFormats = hasRichTextFormats(typeStrings: typeStrings)

        return hasImageTypes || nsImageReadable || hasRichFormats
    }

    /// 将剪贴板完全重写为纯文本，避免 Electron 从 RTF/HTML/TIFF 中读到图片。
    func sanitize(pasteboard: NSPasteboard) -> Bool {
        guard let plainText = extractPlainText(pasteboard: pasteboard), !plainText.isEmpty else {
            return false
        }

        pasteboard.clearContents()
        return pasteboard.setString(plainText, forType: .string)
    }

    private func extractPlainText(pasteboard: NSPasteboard) -> String? {
        if let text = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            return text
        }

        if let rtf = pasteboard.data(forType: .rtf),
           let attributed = NSAttributedString(rtf: rtf, documentAttributes: nil) {
            let text = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }

        if let html = pasteboard.data(forType: .html),
           let attributed = try? NSAttributedString(
               data: html,
               options: [.documentType: NSAttributedString.DocumentType.html],
               documentAttributes: nil
           ) {
            let text = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }

        let msHTML = NSPasteboard.PasteboardType("com.microsoft.htmlFormat")
        if let html = pasteboard.data(forType: msHTML),
           let attributed = try? NSAttributedString(
               data: html,
               options: [.documentType: NSAttributedString.DocumentType.html],
               documentAttributes: nil
           ) {
            let text = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }

        return nil
    }

    private func hasRichTextFormats(typeStrings: Set<String>) -> Bool {
        let richTypes: Set<String> = [
            "public.rtf",
            "public.html",
            "NSRTFPboardType",
            "NSHTMLPboardType",
            "com.microsoft.htmlFormat",
            "com.microsoft.webarchive",
        ]
        if !typeStrings.isDisjoint(with: richTypes) {
            return true
        }
        return typeStrings.contains { $0.lowercased().contains("html") || $0.lowercased().contains("rtf") }
    }

    private func hasImageRepresentation(typeStrings: Set<String>) -> Bool {
        if !typeStrings.isDisjoint(with: Self.imageTypes) {
            return true
        }
        return typeStrings.contains { raw in
            Self.imagePrefixes.contains { raw.hasPrefix($0) }
        }
    }

    private func hasMicrosoftClipboardTypes(typeStrings: Set<String>) -> Bool {
        typeStrings.contains { $0.hasPrefix("com.microsoft.") }
    }

    private func isFromMicrosoftOffice(_ app: NSRunningApplication?) -> Bool {
        guard let bundleID = app?.bundleIdentifier else {
            return false
        }
        if Self.officeBundleIDs.contains(bundleID) {
            return true
        }
        return bundleID.hasPrefix("com.microsoft.")
    }
}
