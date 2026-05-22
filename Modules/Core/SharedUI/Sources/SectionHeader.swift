import SwiftUI
import DesignSystem

/// Consistent section header used across features. Lives here so the visual
/// rhythm of "title + optional trailing accessory" is identical everywhere.
public struct SectionHeader<Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let trailing: Trailing

    public init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Type.titleSection)
                    .foregroundStyle(Palette.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(Type.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer(minLength: Spacing.sm.value)
            trailing
        }
    }
}
