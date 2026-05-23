import SwiftUI
import SwiftData
import DesignSystem
import SharedUI
import SecurityKit
import PersistenceKit

public enum SettingsFeature {
    public enum Route: Hashable, Sendable {
        case aiProviders
        case privacy
        case about
    }

    @MainActor
    public static func rootView(keychain: Keychain) -> some View {
        SettingsScreen(viewModel: SettingsViewModel(keychain: keychain))
    }
}

// MARK: - View Model

@MainActor
@Observable
final class SettingsViewModel {
    let keychain: Keychain
    var deepSeekKeyConfigured: Bool = false
    var ollamaEndpoint: String = UserDefaults.standard.string(forKey: "ollama.endpoint") ?? "http://localhost:11434"
    var ollamaModel: String = UserDefaults.standard.string(forKey: "ollama.model") ?? "llama3.2"

    init(keychain: Keychain) {
        self.keychain = keychain
    }

    func refresh() async {
        deepSeekKeyConfigured = await keychain.exists(.deepSeekAPIKey)
    }

    func saveOllamaConfig() {
        UserDefaults.standard.set(ollamaEndpoint, forKey: "ollama.endpoint")
        UserDefaults.standard.set(ollamaModel, forKey: "ollama.model")
    }
}

// MARK: - Screen

@MainActor
struct SettingsScreen: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var ctx
    @State private var showDeepSeekEntry = false

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(spacing: Spacing.lg.value) {
                        aiProvidersCard
                        ollamaCard
                        privacyCard
                        #if DEBUG
                        debugCard
                        #endif
                        aboutCard
                    }
                    .padding(.horizontal, .md)
                    .padding(.top, .md)
                    .padding(.bottom, .xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.refresh() }
            .sheet(isPresented: $showDeepSeekEntry) {
                APIKeyEntryView(
                    title: "DeepSeek API Key",
                    key: .deepSeekAPIKey,
                    keychain: viewModel.keychain
                ) { _ in
                    showDeepSeekEntry = false
                    Task { await viewModel.refresh() }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var aiProvidersCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("AI Providers", subtitle: "On-device first")

                providerRow(
                    title: "Apple Intelligence",
                    detail: "Primary — on-device, no setup",
                    enabled: true
                )
                Divider().background(Palette.separator)

                providerRow(
                    title: "MLX",
                    detail: "Phase 4b — coming",
                    enabled: false
                )
                Divider().background(Palette.separator)

                providerRow(
                    title: "Ollama",
                    detail: "Configure endpoint below",
                    enabled: true
                )
                Divider().background(Palette.separator)

                Button {
                    showDeepSeekEntry = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DeepSeek")
                                .font(Type.bodyEmph)
                                .foregroundStyle(Palette.textPrimary)
                            Text(viewModel.deepSeekKeyConfigured
                                 ? "API key in Keychain · tap to replace"
                                 : "Tap to add API key")
                                .font(Type.caption)
                                .foregroundStyle(Palette.textSecondary)
                        }
                        Spacer()
                        Circle()
                            .fill(viewModel.deepSeekKeyConfigured ? Palette.success : Palette.textTertiary.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var ollamaCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Ollama", subtitle: "Local server")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Endpoint").font(Type.label).foregroundStyle(Palette.textSecondary)
                    TextField("http://localhost:11434", text: $viewModel.ollamaEndpoint)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(Type.mono)
                        .padding(.horizontal, Spacing.sm.value)
                        .padding(.vertical, Spacing.xs.value)
                        .glass(.raised, in: Capsule())
                        .clipShape(Capsule())
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model").font(Type.label).foregroundStyle(Palette.textSecondary)
                    TextField("llama3.2", text: $viewModel.ollamaModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(Type.mono)
                        .padding(.horizontal, Spacing.sm.value)
                        .padding(.vertical, Spacing.xs.value)
                        .glass(.raised, in: Capsule())
                        .clipShape(Capsule())
                }
                HStack {
                    Spacer()
                    GlassButton("Save", systemImage: "checkmark") {
                        viewModel.saveOllamaConfig()
                    }
                }
            }
        }
    }

    private var privacyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Privacy")
                Text("Personal data — journal, finances, health — never leaves your device. Cloud providers are only used when you explicitly route a request through them.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    #if DEBUG
    private var debugCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Debug", subtitle: "Only visible in Debug builds")
                Text("Populate the app with realistic sample data for screenshots and demos.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
                HStack {
                    GlassButton("Seed sample data", systemImage: "sparkles") {
                        SampleData.seed(into: ctx)
                        Haptics.success()
                    }
                    GlassButton("Wipe", systemImage: "trash", tone: .danger) {
                        SampleData.wipe(ctx)
                        Haptics.warn()
                    }
                }
            }
        }
    }
    #endif

    private var aboutCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("About")
                HStack {
                    Text("LifeOS").font(Type.body).foregroundStyle(Palette.textPrimary)
                    Spacer()
                    Text("0.3.0").font(Type.monoCaption).foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }

    private func providerRow(title: String, detail: String, enabled: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Type.bodyEmph).foregroundStyle(Palette.textPrimary)
                Text(detail).font(Type.caption).foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            Circle()
                .fill(enabled ? Palette.success : Palette.textTertiary.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
}
