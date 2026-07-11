#!/usr/bin/env swift
import AppKit

let pb = NSPasteboard.general
print("changeCount:", pb.changeCount)
print("types:", pb.types?.map(\.rawValue) ?? [])
print("string:", pb.string(forType: .string) ?? "(nil)")
print("can init NSImage:", NSImage(pasteboard: pb) != nil)

if let items = pb.pasteboardItems {
    for (i, item) in items.enumerated() {
        print("\n--- item \(i) ---")
        for type in item.types {
            let size = item.data(forType: type)?.count ?? 0
            print("  \(type.rawValue): \(size) bytes")
        }
    }
}

if let app = NSWorkspace.shared.frontmostApplication {
    print("\nfrontmost:", app.bundleIdentifier ?? "?", app.localizedName ?? "?")
}
