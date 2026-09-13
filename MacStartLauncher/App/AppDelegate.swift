import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var environment: AppEnvironment?
    private var panelController: LauncherPanelController?
    private var statusItem: NSStatusItem?
    private var serviceProvider: LauncherServiceProvider?
    private var hotKeyController: GlobalHotKeyController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let environment = AppEnvironment()
        self.environment = environment
        environment.start()

        let panelController = LauncherPanelController(environment: environment)
        self.panelController = panelController

        let serviceProvider = LauncherServiceProvider(panelController: panelController)
        self.serviceProvider = serviceProvider
        NSApp.servicesProvider = serviceProvider

        let hotKeyController = GlobalHotKeyController { [weak self] in
            self?.panelController?.toggle()
        }
        self.hotKeyController = hotKeyController
        hotKeyController.register()

        configureStatusItem()

        panelController.show()
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "square.grid.2x2",
                accessibilityDescription: "Start"
            )
            button.toolTip = "Start Launcher"
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = statusItem
    }

    // MARK: - Status item

    @objc private func statusItemClicked() {
        switch NSApp.currentEvent?.type {
        case .rightMouseUp:
            panelController?.hide()
            showStatusMenu()
        default:
            panelController?.toggle()
        }
    }

    private func showStatusMenu() {
        let menu = NSMenu()

        let exportItem = NSMenuItem(
            title: "Export Settings…",
            action: #selector(exportSettings),
            keyEquivalent: ""
        )
        exportItem.target = self
        menu.addItem(exportItem)

        let importItem = NSMenuItem(
            title: "Import Settings…",
            action: #selector(importSettings),
            keyEquivalent: ""
        )
        importItem.target = self
        menu.addItem(importItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Start",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func exportSettings() {
        environment?.settingsTransfer.exportSettings()
    }

    @objc private func importSettings() {
        guard let environment, let panelController else { return }

        let knownIdentifiers = Set(environment.launcher.applications.map(\.bundleIdentifier))
        do {
            guard let result = try environment.settingsTransfer.importSettings(
                knownBundleIdentifiers: knownIdentifiers
            ) else {
                return
            }
            environment.reloadFromPreferences()
            panelController.show()
            presentImportSummary(result)
        } catch {
            presentError(error)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func presentImportSummary(_ result: SettingsImportResult) {
        var lines = [
            "Imported \(result.pinnedApplications) pinned applications and \(result.pinnedFolders) folders."
        ]
        if !result.missingApplications.isEmpty {
            lines.append("Not installed: \(result.missingApplications.joined(separator: ", ")).")
        }
        if !result.missingFolders.isEmpty {
            lines.append("Folders not found: \(result.missingFolders.joined(separator: ", ")).")
        }

        let alert = NSAlert()
        alert.messageText = "Import Complete"
        alert.informativeText = lines.joined(separator: "\n\n")
        alert.alertStyle = result.hasWarnings ? .warning : .informational
        alert.runModal()
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Import Failed"
        alert.informativeText = (error as? LocalizedError)?.errorDescription
            ?? error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }

    // MARK: - Dock and reopen

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        panelController?.toggle()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
