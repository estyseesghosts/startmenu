import SwiftUI

/// Opens an `NSOpenPanel` to add a custom folder shortcut.
struct AddFolderButton: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        Button {
            environment.folders.addFolder()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("Add Folder")
                    .font(.system(size: 13))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(HoverButtonStyle())
    }
}
