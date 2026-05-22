import SwiftUI
import DesignSystem
import SharedUI
import PersistenceKit

struct NoteRow: View {
    let note: Note
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            onTap()
        }) {
            HStack(alignment: .top, spacing: Spacing.sm.value) {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                        .padding(.top, 4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(note.displayTitle)
                        .font(Type.bodyEmph)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)

                    if !note.bodyPreview.isEmpty && note.title != note.bodyPreview {
                        Text(note.bodyPreview)
                            .font(Type.bodySoft)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(2)
                    }

                    Text(note.updatedAt, style: .relative)
                        .font(Type.captionTight)
                        .foregroundStyle(Palette.textTertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(.md)
            .frame(maxWidth: .infinity)
            .glass(.raised, in: Radius.md.shape)
            .clipShape(Radius.md.shape)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
