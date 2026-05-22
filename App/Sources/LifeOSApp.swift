import SwiftUI
import SwiftData
import DesignSystem

@main
struct LifeOSApp: App {
    @State private var container = AppContainer()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasSeenOnboarding {
                    RootView(container: container)
                } else {
                    OnboardingView()
                        .transition(.opacity)
                }
            }
            .animation(Motion.gentle, value: hasSeenOnboarding)
            .modelContainer(container.modelContainer)
            .preferredColorScheme(.dark)
            .tint(Palette.accent)
        }
    }
}
