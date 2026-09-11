import AppKit
import SwiftUI

/// A single application cell with a native context menu and hover state.
struct AppTile: View {
    let application: InstalledApplication
    let isSelected: Bool

    @Environment(AppEnvironment.self) private var environment
    @State private var isHovering = false

    private var launcher: LauncherViewModel { environment.launcher }

    var body: some View {
        Button {
            launcher.open(application)
        } label: {
            VStack(spacing: 6) {
                Image(nsImage: environment.iconService.icon(for: application))
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 48, height: 48)

                Text(application.name)
                    .font(.system(size: 11))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
            .background(tileBackground)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .contextMenu { contextMenu }
        .help(application.name)
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("Open") {
            launcher.open(application)
        }

        if launcher.isPinned(application) {
            Button("Unpin from Launcher") {
                launcher.unpin(application)
            }
        } else {
            Button("Pin to Launcher") {
                launcher.pin(application)
            }
            .disabled(!launcher.canPinMore)
        }

        Divider()

        Button("Show in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([application.url])
        }
    }

    private var tileBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(0.22)
        }
        return isHovering ? Color.primary.opacity(0.08) : .clear
    }
}
