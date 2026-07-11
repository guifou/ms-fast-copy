#!/usr/bin/env swift
import AppKit

// 与 App 相同的 sanitizer 源码一起编译运行
// swift scripts/integration-test.swift Sources/ClipboardSanitizer.swift

@MainActor
func simulateOfficeClipboard() {
    let pb = NSPasteboard.general
    let sample = "Integration test 文字"

    pb.clearContents()
    let item = NSPasteboardItem()
    item.setString(sample, forType: .string)
    item.setData("{\\rtf1\\ansi test}".data(using: .utf8)!, forType: .rtf)
    item.setData(
        "<html><body>test</body></html>".data(using: .utf8)!,
        forType: NSPasteboard.PasteboardType("com.microsoft.htmlFormat")
    )
    let img = NSImage(size: NSSize(width: 50, height: 20), flipped: false) { r in
        NSColor.red.setFill(); r.fill(); return true
    }
    item.setData(img.tiffRepresentation!, forType: .tiff)
    pb.writeObjects([item])

    print("before types:", pb.types?.map(\.rawValue) ?? [])
    print("before NSImage:", NSImage(pasteboard: pb) != nil)

    let sanitizer = ClipboardSanitizer()
    let app = NSRunningApplication.current
    let (should, reason) = sanitizer.shouldSanitize(pasteboard: pb, sourceApp: app)
    print("shouldSanitize:", should, reason ?? "")

    if should {
        _ = sanitizer.sanitize(pasteboard: pb)
    }

    print("after types:", pb.types?.map(\.rawValue) ?? [])
    print("after string:", pb.string(forType: .string) ?? "")
    print("after NSImage:", NSImage(pasteboard: pb) != nil)
}

simulateOfficeClipboard()
