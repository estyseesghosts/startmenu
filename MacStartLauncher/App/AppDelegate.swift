import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var environment: AppEnvironment?
    private var panelController: LauncherPanelController?
    private var statusItem: NSStatusItem?

    func applicationWillFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            NSApp.setActivationPolicy(.regular)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let environment = AppEnvironment()
        self.environment = environment
        environment.start()

        let panelController = LauncherPanelController(environment: environment)
        self.panelController = panelController

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "square.grid.2x2",
                accessibilityDescription: "Start"
            )
            button.toolTip = "Start Launcher"
            button.target = self
            button.action = #selector(toggleLauncher)
        }
        self.statusItem = statusItem

        panelController.show()
    }

    @objc private func toggleLauncher() {
        panelController?.toggle()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
