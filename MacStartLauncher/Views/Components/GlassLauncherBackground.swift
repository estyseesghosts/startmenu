import SwiftUI

/// Applies the single large Liquid Glass surface that hosts the launcher.
struct GlassLauncherBackground: ViewModifier {
    var cornerRadius: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func glassLauncherBackground(cornerRadius: CGFloat = 28) -> some View {
        modifier(GlassLauncherBackground(cornerRadius: cornerRadius))
    }
}
