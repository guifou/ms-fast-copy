import AppKit

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ClipboardMonitor()
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        monitor.loadSettings()
        monitor.start()

        menuBar = MenuBarController(monitor: monitor)
        menuBar?.setup()

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}
