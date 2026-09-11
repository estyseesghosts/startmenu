import AppKit
import Observation

/// Owns the right-hand folder shortcuts and the folder picker.
@MainActor
@Observable
final class FolderShortcutsViewModel {
    private let service: FolderShortcutServicing
    private let preferencesStore: PreferencesStoring

    let standardShortcuts: [FolderShortcut]
    private(set) var customShortcuts: [FolderShortcut] = []

    var allShortcuts: [FolderShortcut] {
        standardShortcuts + customShortcuts
    }

    init(
        service: FolderShortcutServicing,
        preferencesStore: PreferencesStoring
    ) {
        self.service = service
        self.preferencesStore = preferencesStore
        self.standardShortcuts = FolderShortcut.standardShortcuts()
        self.customShortcuts = preferencesStore.load().additionalFolders
        refreshCustomShortcuts()
    }

    func url(for shortcut: FolderShortcut) -> URL? {
        service.url(for: shortcut)
    }

    func open(_ shortcut: FolderShortcut) {
        service.open(shortcut)
    }

    func reveal(_ shortcut: FolderShortcut) {
        service.reveal(shortcut)
    }

    func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Add Folder"
        panel.message = "Choose a folder to show in the launcher."

        guard panel.runModal() == .OK, let url = panel.url else { return }
        addFolder(at: url)
    }

    func addFolder(at url: URL) {
        do {
            let shortcut = try service.makeCustomShortcut(from: url)
            customShortcuts.append(shortcut)
            persist()
        } catch {
            // Adding a folder is best effort; unreadable locations are ignored.
        }
    }

    func remove(_ shortcut: FolderShortcut) {
        guard shortcut.isCustom else { return }
        customShortcuts.removeAll { $0.id == shortcut.id }
        persist()
    }

    /// Regenerates stale bookmarks and drops shortcuts that can no longer be
    /// resolved.
    func refreshCustomShortcuts() {
        var refreshed: [FolderShortcut] = []
        var changed = false

        for shortcut in customShortcuts {
            if let updated = service.refresh(shortcut) {
                if updated != shortcut {
                    changed = true
                }
                refreshed.append(updated)
            } else {
                changed = true
            }
        }

        if changed {
            customShortcuts = refreshed
            persist()
        }
    }

    private func persist() {
        var preferences = preferencesStore.load()
        preferences.additionalFolders = customShortcuts
        preferencesStore.save(preferences)
    }
}
