import SwiftUI
import DesignSystem
import SharedUI
import SecurityKit

/// Secure API key entry. Writes to Keychain with biometric protection on.
/// On a successful save, the key NEVER leaves Keychain — it's read by the
/// provider just-in-time per request.
@MainActor
public struct APIKeyEntryView: View {
    private let title: String
    private let key: Keychain.Key
    private let keychain: Keychain
    private let onDismiss: (Bool) -> Void  // true if a key was saved/changed

    @State private var input: String = ""
    @State private var isSubmitting = false
    @State private var error: String? = nil
    @State private var existing: Bool = false
    @State private var revealed = false

    public init(
        title: String,
        key: Keychain.Key,
        keychain: Keychain,
        onDismiss: @escaping (Bool) -> Void
    ) {
        self.title = title
        self.key = key
        self.keychain = keychain
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Group {
                        if revealed {
                            TextField("API key", text: $input)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .font(Type.mono)
                        } else {
                            SecureField("API key", text: $input)
                                .textContentType(.password)
                                .font(Type.mono)
                        }
                    }
                } header: {
                    Text(title)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saved to iCloud Keychain on this device only, protected by Face ID. Never written to logs, defaults, or source.")
                        if let error {
                            Text(error).foregroundStyle(Palette.danger)
                        }
                    }
                    .font(Type.caption)
                }

                Section {
                    Toggle("Show characters", isOn: $revealed)
                }

                if existing {
                    Section {
                        Button("Remove saved key", role: .destructive) {
                            Task { await remove() }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.surface.ignoresSafeArea())
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onDismiss(false) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
            .task {
                existing = await keychain.exists(key)
            }
        }
    }

    private func save() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await keychain.set(input.trimmingCharacters(in: .whitespaces), for: key, requireBiometry: true)
            Haptics.success()
            onDismiss(true)
        } catch {
            self.error = "Couldn't save key: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    private func remove() async {
        do {
            try await keychain.delete(key)
            existing = false
            input = ""
            Haptics.warn()
        } catch {
            self.error = "Couldn't remove key: \(error.localizedDescription)"
        }
    }
}
