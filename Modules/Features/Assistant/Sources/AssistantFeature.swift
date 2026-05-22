import SwiftUI
import AIKit

/// Public surface of the Assistant feature.
///
/// The Assistant is NOT a tab — it's a contextual overlay summoned from
/// anywhere in the app. That's intentional: Apple Intelligence-style
/// assistants feel like a presence, not a destination.
public enum AssistantFeature {
    @MainActor
    public static func rootView(router: AIRouter) -> some View {
        AssistantScreen(viewModel: AssistantViewModel(router: router))
    }
}
