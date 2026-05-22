import SwiftUI
import DesignSystem

/// The atomic surface of LifeOS. A glass-clad rounded rectangle with the
/// design system's spacing and radius applied. Use everywhere we'd otherwise
/// reach for a plain `VStack { ... }.background(.regularMaterial)`.
public struct GlassCard<Content: View>: View {
    private let tier: GlassTier
    private let radius: Radius
    private let padding: Spacing
    private let content: Content

    public init(
        tier: GlassTier = .raised,
        radius: Radius = .md,
        padding: Spacing = .md,
        @ViewBuilder content: () -> Content
    ) {
        self.tier = tier
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(tier, in: radius.shape)
            .clipShape(radius)
    }
}
