import SwiftUI

/// The automatic category folders shown after the pinned applications.
struct CategoryGridView: View {
    @Environment(AppEnvironment.self) private var environment

    private var launcher: LauncherViewModel { environment.launcher }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !launcher.categoryOverviews.isEmpty {
                Text("Categories")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)

                LazyVGrid(columns: AppGridView.columns, alignment: .leading, spacing: 10) {
                    ForEach(launcher.categoryOverviews) { overview in
                        let entryID = "category:\(overview.group.id)"
                        CategoryTile(
                            overview: overview,
                            isSelected: launcher.grid.selectedEntry?.id == entryID
                        )
                        .id(entryID)
                    }
                }
            }
        }
    }
}
