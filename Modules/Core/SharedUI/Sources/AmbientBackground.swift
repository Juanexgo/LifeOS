import SwiftUI
import DesignSystem

/// Slow-drifting ambient gradient used behind feature screens. Gives the app
/// a sense of depth and life without a heavy hit on the GPU — two radial
/// gradients, animated with a long phase.
///
/// Apple's Today screens often feel "alive" because something subtle is
/// moving in the background. We're not doing particle effects — just a
/// breath of color motion.
public struct AmbientBackground: View {
    @State private var phase: Double = 0

    public init() {}

    public var body: some View {
        ZStack {
            Palette.surface

            RadialGradient(
                colors: [Palette.accent.opacity(0.18), .clear],
                center: UnitPoint(x: 0.15 + 0.05 * sin(phase),
                                  y: 0.10 + 0.05 * cos(phase)),
                startRadius: 20,
                endRadius: 400
            )
            .blendMode(.plusLighter)

            RadialGradient(
                colors: [Palette.accentSecondary.opacity(0.14), .clear],
                center: UnitPoint(x: 0.85 + 0.05 * cos(phase),
                                  y: 0.85 + 0.05 * sin(phase)),
                startRadius: 20,
                endRadius: 400
            )
            .blendMode(.plusLighter)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: true)) {
                phase = .pi
            }
        }
    }
}
