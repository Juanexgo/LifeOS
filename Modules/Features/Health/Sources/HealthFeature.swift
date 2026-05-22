import SwiftUI
import DesignSystem
import SharedUI
import HealthKitBridge

public enum HealthFeature {
    @MainActor
    public static func rootView() -> some View {
        HealthScreen()
    }
}

@MainActor
struct HealthScreen: View {
    @State private var bridge = HealthKitBridge()
    @State private var snapshot: HealthKitBridge.Snapshot = .empty
    @State private var status: HealthKitBridge.Status = .notDetermined

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg.value) {
                        switch status {
                        case .notDetermined: permissionCard
                        case .denied:        deniedCard
                        case .unavailable:   unavailableCard
                        case .authorized:    dataCard
                        }
                    }
                    .padding(.horizontal, .md)
                    .padding(.top, .md)
                    .padding(.bottom, .xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Health")
            .navigationBarTitleDisplayMode(.large)
            .task {
                status = await bridge.status()
                if status == .authorized {
                    snapshot = await bridge.todaySnapshot()
                }
            }
        }
    }

    private var permissionCard: some View {
        GlassCard(tier: .floating, radius: .lg) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                Label("Health", systemImage: "heart.fill")
                    .font(Type.labelStrong)
                    .foregroundStyle(Palette.danger)
                Text("Connect to Health")
                    .font(Type.titleCard)
                    .foregroundStyle(Palette.textPrimary)
                Text("LifeOS reads steps and active calories for today's overview. Data stays on your device.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
                GlassButton("Allow access", systemImage: "heart") {
                    Task {
                        try? await bridge.requestAccess()
                        status = await bridge.status()
                        if status == .authorized {
                            snapshot = await bridge.todaySnapshot()
                        }
                    }
                }
                .padding(.top, Spacing.xs.value)
            }
        }
    }

    private var deniedCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Access denied")
                Text("Health access was declined. Enable it in Settings → Privacy & Security → Health → LifeOS.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private var unavailableCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Not available")
                Text("HealthKit isn't available on this device.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private var dataCard: some View {
        VStack(spacing: Spacing.md.value) {
            GlassCard(tier: .floating) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Steps today", systemImage: "figure.walk")
                        .font(Type.labelStrong)
                        .foregroundStyle(Palette.accent)
                    Text("\(snapshot.steps)")
                        .font(Type.numeral)
                        .foregroundStyle(Palette.textPrimary)
                        .monospacedDigit()
                }
            }
            GlassCard {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Active calories", systemImage: "flame.fill")
                        .font(Type.labelStrong)
                        .foregroundStyle(.orange)
                    Text("\(snapshot.activeKilocalories) kcal")
                        .font(Type.titleHero)
                        .foregroundStyle(Palette.textPrimary)
                        .monospacedDigit()
                }
            }
        }
    }
}
