#!/usr/bin/env swift
import AppKit

// 模拟 Office 复制：纯文本 + RTF + TIFF（类似 Word 行为）
let pb = NSPasteboard.general
let sample = "Hello from Office 测试文字"

pb.clearContents()

let item = NSPasteboardItem()
item.setString(sample, forType: .string)

// 伪造 RTF（含文字）
let rtf = "{\\rtf1\\ansi\\deff0 Hello from Office 测试文字}".data(using: .utf8)!
item.setData(rtf, forType: .rtf)

// 伪造 Microsoft HTML 格式
let html = "<html><body><p>Hello from Office 测试文字</p></body></html>".data(using: .utf8)!
item.setData(html, forType: NSPasteboard.PasteboardType("com.microsoft.htmlFormat"))

// 放一张 1x1 图片，模拟 Office 附带的 TIFF 快照
let image = NSImage(size: NSSize(width: 100, height: 30), flipped: false) { rect in
    NSColor.white.setFill()
    rect.fill()
    return true
}
if let tiff = image.tiffRepresentation {
    item.setData(tiff, forType: .tiff)
}

pb.writeObjects([item])

print("BEFORE sanitize")
print("types:", pb.types?.map(\.rawValue) ?? [])
print("string:", pb.string(forType: .string) ?? "")
print("NSImage readable:", NSImage(pasteboard: pb) != nil)

// 内联测试 sanitizer 逻辑
@MainActor
func run() {
    // 直接编译进 app 的类无法从这里引用，手动执行同等逻辑
    let text = pb.string(forType: .string) ?? ""
    pb.clearContents()
    pb.setString(text, forType: .string)

    print("\nAFTER plain-text rewrite")
    print("types:", pb.types?.map(\.rawValue) ?? [])
    print("string:", pb.string(forType: .string) ?? "")
    print("NSImage readable:", NSImage(pasteboard: pb) != nil)
}

run()
