import SwiftUI
import DesignSystem
import SharedUI

/// First-launch experience. 3 pages, each one a different "this is what
/// LifeOS does" pitch. Lives in the App layer because it composes feature
/// concepts but isn't owned by any one feature.
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page: Int = 0

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    pageView(
                        icon: "sparkles",
                        tint: Palette.accentSecondary,
                        title: "An assistant that\nstays on your device",
                        body: "LifeOS uses Apple Intelligence on your iPhone. Your prompts, notes, and tasks never leave the device."
                    ).tag(0)

                    pageView(
                        icon: "checklist",
                        tint: Palette.accent,
                        title: "Tasks, notes, focus\nin one calm place",
                        body: "Markdown notes, a Pomodoro that respects your time, and a task list with smart priority and due-date awareness."
                    ).tag(1)

                    pageView(
                        icon: "lock.shield",
                        tint: Palette.success,
                        title: "Yours, locked\nbehind Face ID",
                        body: "API keys live in the Keychain, biometric-protected. Personal data is private by default — cloud is opt-in."
                    ).tag(2)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                GlassButton(page < 2 ? "Continue" : "Get started", systemImage: page < 2 ? "arrow.right" : "checkmark") {
                    if page < 2 {
                        withAnimation(Motion.gentle) { page += 1 }
                    } else {
                        Haptics.commit()
                        hasSeenOnboarding = true
                    }
                }
                .padding(.horizontal, .lg)
                .padding(.bottom, .xl)
            }
        }
    }

    private func pageView(icon: String, tint: Color, title: String, body: String) -> some View {
        VStack(spacing: Spacing.lg.value) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(tint)
                .padding(.bottom, Spacing.sm.value)
            Text(title)
                .font(Type.titleHero)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .lg)
            Text(body)
                .font(Type.body)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .xl)
            Spacer()
            Spacer()
        }
    }
}
