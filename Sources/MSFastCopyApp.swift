import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ClipboardMonitor()
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor.loadSettings()
        monitor.start()

        menuBar = MenuBarController(monitor: monitor)
        menuBar?.setup()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}
