import AppKit
import SwiftUI

/// A single folder shortcut row with a native context menu.
struct FolderShortcutRow: View {
    let shortcut: FolderShortcut

    @Environment(AppEnvironment.self) private var environment
    @State private var isHovering = false

    private var folders: FolderShortcutsViewModel { environment.folders }

    var body: some View {
        Button {
            folders.open(shortcut)
        } label: {
            HStack(spacing: 10) {
                FolderShortcutIcon(url: folders.url(for: shortcut))
                Text(shortcut.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .contextMenu { contextMenu }
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("Open") {
            folders.open(shortcut)
        }
        Button("Show in Finder") {
            folders.reveal(shortcut)
        }
        if shortcut.isCustom {
            Divider()
            Button("Remove from Launcher", role: .destructive) {
                folders.remove(shortcut)
            }
        }
    }

    private var rowBackground: Color {
        isHovering ? Color.primary.opacity(0.08) : .clear
    }
}

/// Displays the native Finder folder icon when the location can be resolved.
private struct FolderShortcutIcon: View {
    let url: URL?

    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        Group {
            if let url {
                Image(nsImage: environment.iconService.folderIcon(for: url))
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: "folder")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 18, height: 18)
    }
}
