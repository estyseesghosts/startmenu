import AppKit

protocol FolderShortcutServicing {
    func url(for shortcut: FolderShortcut) -> URL?
    func open(_ shortcut: FolderShortcut)
    func reveal(_ shortcut: FolderShortcut)
    func makeCustomShortcut(from url: URL) throws -> FolderShortcut
    /// Returns the shortcut with a regenerated bookmark when the stored one is
    /// stale, or `nil` when the folder can no longer be resolved.
    func refresh(_ shortcut: FolderShortcut) -> FolderShortcut?
}

/// Resolves and acts on right-pane folder shortcuts.
///
/// Standard shortcuts are derived from `FileManager` on demand. Custom
/// shortcuts resolve their security-scoped bookmark.
final class FolderService: FolderShortcutServicing {
    private let fileManager: FileManager
    private let bookmarkStore: BookmarkStoring

    init(fileManager: FileManager = .default, bookmarkStore: BookmarkStoring = SecurityScopedBookmarkStore()) {
        self.fileManager = fileManager
        self.bookmarkStore = bookmarkStore
    }

    func url(for shortcut: FolderShortcut) -> URL? {
        switch shortcut.kind {
        case .home:
            return fileManager.homeDirectoryForCurrentUser
        case .documents:
            return directoryURL(for: .documentDirectory)
        case .desktop:
            return directoryURL(for: .desktopDirectory)
        case .downloads:
            return directoryURL(for: .downloadsDirectory)
        case .custom:
            guard let bookmarkData = shortcut.bookmarkData else { return nil }
            return try? bookmarkStore.resolve(bookmarkData).url
        }
    }

    func open(_ shortcut: FolderShortcut) {
        guard let url = url(for: shortcut) else { return }
        let didAccess = shortcut.isCustom
            ? url.startAccessingSecurityScopedResource()
            : false
        NSWorkspace.shared.open(url)
        if didAccess {
            url.stopAccessingSecurityScopedResource()
        }
    }

    func reveal(_ shortcut: FolderShortcut) {
        guard let url = url(for: shortcut) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func makeCustomShortcut(from url: URL) throws -> FolderShortcut {
        let bookmarkData = try bookmarkStore.makeBookmark(for: url)
        return FolderShortcut(
            id: UUID().uuidString,
            kind: .custom,
            name: url.lastPathComponent,
            bookmarkData: bookmarkData
        )
    }

    func refresh(_ shortcut: FolderShortcut) -> FolderShortcut? {
        guard shortcut.kind == .custom, let bookmarkData = shortcut.bookmarkData else {
            return shortcut
        }
        do {
            let resolved = try bookmarkStore.resolve(bookmarkData)
            guard resolved.isStale else { return shortcut }

            var updated = shortcut
            updated.bookmarkData = try bookmarkStore.makeBookmark(for: resolved.url)
            updated.name = resolved.url.lastPathComponent
            return updated
        } catch {
            return nil
        }
    }

    private func directoryURL(for directory: FileManager.SearchPathDirectory) -> URL? {
        try? fileManager.url(
            for: directory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
    }
}
