import SwiftUI

/// A reusable Liquid Glass surface for one launcher component.
///
/// The launcher is composed of three separate floating surfaces (app grid,
/// search, files). Each surface applies this modifier, and the root wraps them
/// in a single `GlassEffectContainer` so their shapes render together without
/// merging into one large rectangle.
struct GlassSurface: ViewModifier {
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
    func glassSurface(cornerRadius: CGFloat = 28) -> some View {
        modifier(GlassSurface(cornerRadius: cornerRadius))
    }
}
