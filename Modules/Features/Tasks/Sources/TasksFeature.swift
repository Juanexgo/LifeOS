import SwiftUI
import DesignSystem
import SharedUI
import PersistenceKit

/// Public surface of the Tasks feature.
public enum TasksFeature {
    public enum Route: Hashable, Sendable {
        case detail(UUID)
        case newTask
    }

    @MainActor
    public static func rootView() -> some View {
        TasksScreen()
    }
}
