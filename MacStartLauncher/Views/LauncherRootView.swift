import SwiftUI

/// The launcher's root: three independently floating Liquid Glass surfaces.
///
/// There is no outer launcher rectangle and no divider. A single
/// `GlassEffectContainer` renders the app grid, the search field, and the files
/// pane together while keeping them visually separate.
struct LauncherRootView: View {
    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(spacing: 12) {
                    AppPaneView()
                        .padding(18)
                        .glassSurface(cornerRadius: 28)

                    LauncherSearchField()
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .glassSurface(cornerRadius: 18)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                FolderPaneView()
                    .padding(16)
                    .frame(width: 240)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .glassSurface(cornerRadius: 28)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
