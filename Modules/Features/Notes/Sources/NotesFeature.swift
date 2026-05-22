import SwiftUI
import DesignSystem
import SharedUI
import PersistenceKit

public enum NotesFeature {
    public enum Route: Hashable, Sendable {
        case detail(UUID)
        case newNote
    }

    @MainActor
    public static func rootView() -> some View {
        NotesScreen()
    }
}
