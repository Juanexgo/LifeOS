import SwiftUI
import DesignSystem

/// Concentric ring used for "tasks done today", focus session minutes, etc.
/// Animates progress changes via Motion.gentle for a polished feel.
public struct ProgressRing: View {
    private let progress: Double          // 0.0 ... 1.0
    private let size: CGFloat
    private let lineWidth: CGFloat
    private let tint: Color

    public init(
        progress: Double,
        size: CGFloat = 64,
        lineWidth: CGFloat = 8,
        tint: Color = Palette.accent
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.separator, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.5), tint, tint.opacity(0.85)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Motion.gentle, value: progress)
        }
        .frame(width: size, height: size)
    }
}
