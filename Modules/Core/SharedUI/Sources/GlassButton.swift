import SwiftUI
import DesignSystem

/// Pill-shaped glass button. Used for primary actions where we want an
/// Apple-Intelligence-style "summon" feel — Assistant CTA, "Add task", etc.
public struct GlassButton: View {
    public enum Tone: Sendable { case primary, secondary, danger }

    private let title: String
    private let systemImage: String?
    private let tone: Tone
    private let action: () -> Void

    public init(
        _ title: String,
        systemImage: String? = nil,
        tone: Tone = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tone = tone
        self.action = action
    }

    public var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(Type.bodyEmph)
            }
            .padding(.horizontal, Spacing.md.value)
            .padding(.vertical, Spacing.sm.value)
            .foregroundStyle(foreground)
            .glass(.floating, in: Capsule())
            .overlay(Capsule().strokeBorder(stroke, lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch tone {
        case .primary:   return Palette.textPrimary
        case .secondary: return Palette.textSecondary
        case .danger:    return Palette.danger
        }
    }

    private var stroke: Color {
        switch tone {
        case .primary:   return Palette.accent.opacity(0.4)
        case .secondary: return Palette.separator
        case .danger:    return Palette.danger.opacity(0.5)
        }
    }
}
