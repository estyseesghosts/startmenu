import Foundation

protocol BookmarkStoring {
    func makeBookmark(for url: URL) throws -> Data
    func resolve(_ bookmarkData: Data) throws -> ResolvedBookmark
}

struct ResolvedBookmark {
    let url: URL
    let isStale: Bool
}

/// Creates and resolves security-scoped bookmarks for custom folder shortcuts.
struct SecurityScopedBookmarkStore: BookmarkStoring {
    func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    func resolve(_ bookmarkData: Data) throws -> ResolvedBookmark {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return ResolvedBookmark(url: url, isStale: isStale)
    }
}
