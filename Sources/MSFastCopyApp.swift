import AppKit
import SwiftUI

@main
struct MSFastCopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ClipboardMonitor()
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard AppEnvironment.acquireSingleInstance() else {
            NSApp.terminate(nil)
            return
        }

        if AppEnvironment.isTranslocated {
            AppEnvironment.showTranslocationAlert()
        }

        monitor.loadSettings()
        monitor.start()

        menuBar = MenuBarController(monitor: monitor)
        menuBar?.setup()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}
