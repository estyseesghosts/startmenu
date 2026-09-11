import AppKit
import SwiftUI

/// The pinned application grid.
///
/// The first three rows hold at most twelve pinned applications. Drag and drop
/// reorders them within those slots.
struct PinnedAppsView: View {
    @Environment(AppEnvironment.self) private var environment

    private var launcher: LauncherViewModel { environment.launcher }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pinned")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 2)

            LazyVGrid(columns: AppGridView.columns, alignment: .leading, spacing: 10) {
                ForEach(launcher.pinnedApplications) { application in
                    let entryID = "app:\(application.id)"
                    AppTile(
                        application: application,
                        isSelected: launcher.grid.selectedEntry?.id == entryID
                    )
                    .id(entryID)
                    .onDrag {
                        NSItemProvider(object: application.id as NSString)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let droppedID = items.first else { return false }
                        launcher.movePin(id: droppedID, before: application.id)
                        return true
                    }
                }
            }
        }
    }
}
