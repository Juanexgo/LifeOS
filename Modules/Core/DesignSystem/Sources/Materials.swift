import SwiftUI

/// Liquid Glass wrappers. iOS 26 ships `.glassEffect` natively — these
/// semantic aliases keep call sites stable if Apple renames the API again
/// and let us swap to legacy `.ultraThinMaterial` on older devices.
public enum GlassTier: Sendable {
    /// Default app chrome — toolbars, tab bars.
    case primary
    /// Cards, popovers — slightly more pronounced.
    case raised
    /// Floating overlays, sheets, alerts. Strongest blur, brightest highlight.
    case floating
}

public extension View {
    /// Apply LifeOS glass. Falls back to `.ultraThinMaterial` if a future
    /// build is ever run below iOS 26 (we deploy iOS 26 today, but feature
    /// modules may grow widget extensions on lower targets).
    @ViewBuilder
    func glass(_ tier: GlassTier = .primary, in shape: some Shape = .rect) -> some View {
        if #available(iOS 26.0, *) {
            switch tier {
            case .primary:
                self.glassEffect(.regular, in: shape)
            case .raised:
                self.glassEffect(.regular.tint(.white.opacity(0.04)), in: shape)
            case .floating:
                self.glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    /// A glass surface used as a container — wraps with padding + clip.
    func glassSurface(_ tier: GlassTier = .raised, radius: Radius = .md) -> some View {
        padding(.md)
            .background {
                radius.shape.fill(.clear)
            }
            .glass(tier, in: radius.shape)
            .clipShape(radius)
    }
}

/// Optional container for grouping multiple glass elements so iOS 26 can
/// blend their refraction/highlights together (`GlassEffectContainer`).
public struct GlassGroup<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer { content }
        } else {
            content
        }
    }
}
