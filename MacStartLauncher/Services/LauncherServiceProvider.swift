import AppKit

/// Receives the macOS Service used for the user-assigned keyboard shortcut.
///
/// Registering a Service lets the user bind a shortcut in System Settings →
/// Keyboard → Keyboard Shortcuts → Services, without the launcher requesting
/// Accessibility trust for a global event monitor.
@MainActor
final class LauncherServiceProvider: NSObject {
    weak var panelController: LauncherPanelController?

    init(panelController: LauncherPanelController) {
        self.panelController = panelController
        super.init()
    }

    @objc func toggleStartMenu(
        _ pasteboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        panelController?.toggle()
    }
}
