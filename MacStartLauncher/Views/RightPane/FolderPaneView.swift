import SwiftUI

/// The right pane: standard and custom folder shortcuts.
struct FolderPaneView: View {
    @Environment(AppEnvironment.self) private var environment

    private var folders: FolderShortcutsViewModel { environment.folders }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Folders")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
                .padding(.bottom, 4)

            ForEach(folders.allShortcuts) { shortcut in
                FolderShortcutRow(shortcut: shortcut)
            }

            Divider()
                .padding(.vertical, 8)

            AddFolderButton()

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
