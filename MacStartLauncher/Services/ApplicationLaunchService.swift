import AppKit

protocol ApplicationLaunching {
    func launch(_ application: InstalledApplication, completion: @escaping () -> Void)
}

/// Launches a selected bundle through `NSWorkspace`.
final class ApplicationLaunchService: ApplicationLaunching {
    func launch(_ application: InstalledApplication, completion: @escaping () -> Void) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(
            at: application.url,
            configuration: configuration
        ) { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
