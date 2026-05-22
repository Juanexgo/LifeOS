import SwiftUI
import DesignSystem
import SharedUI
import PersistenceKit

public enum FocusFeature {
    public enum Route: Hashable, Sendable {
        case sessionActive
        case history
    }

    @MainActor
    public static func rootView() -> some View {
        FocusScreen()
    }
}
