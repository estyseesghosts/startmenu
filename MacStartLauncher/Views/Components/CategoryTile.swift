import SwiftUI

/// A category folder tile that previews up to four member application icons.
struct CategoryTile: View {
    let overview: CategoryOverview
    let isSelected: Bool

    @Environment(AppEnvironment.self) private var environment
    @State private var isHovering = false

    private var previewApplications: [InstalledApplication] {
        Array(overview.apps.prefix(4))
    }

    var body: some View {
        Button {
            environment.launcher.navigation = .group(overview.group)
        } label: {
            VStack(spacing: 6) {
                previewGrid
                    .frame(width: 52, height: 52)

                Text(overview.group.displayName)
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
        .help("\(overview.group.displayName) — \(overview.apps.count) apps")
    }

    private var previewGrid: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                previewIcon(at: 0)
                previewIcon(at: 1)
            }
            HStack(spacing: 3) {
                previewIcon(at: 2)
                previewIcon(at: 3)
            }
        }
    }

    @ViewBuilder
    private func previewIcon(at index: Int) -> some View {
        if index < previewApplications.count {
            Image(nsImage: environment.iconService.icon(for: previewApplications[index]))
                .resizable()
                .interpolation(.high)
                .frame(width: 22, height: 22)
        } else {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .frame(width: 22, height: 22)
        }
    }

    private var tileBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(0.22)
        }
        return isHovering ? Color.primary.opacity(0.08) : .clear
    }
}
