import SwiftUI
import DesignSystem
import SharedUI
import AIKit

@MainActor
struct AssistantScreen: View {
    @Bindable var viewModel: AssistantViewModel
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                VStack(spacing: 0) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        messageList
                    }
                    inputBar
                }
            }
            .navigationTitle("Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.messages.isEmpty {
                        Button("Clear", role: .destructive) { viewModel.clear() }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md.value) {
            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Palette.accentSecondary)
            Text("How can I help?")
                .font(Type.titleScreen)
                .foregroundStyle(Palette.textPrimary)
            Text(viewModel.availabilityHint)
                .font(Type.bodySoft)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .lg)

            VStack(spacing: 8) {
                suggestion("Summarise my day")
                suggestion("Draft a note about a meeting")
                suggestion("Help me plan tomorrow")
            }
            .padding(.top, Spacing.sm.value)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func suggestion(_ text: String) -> some View {
        Button {
            viewModel.input = text
            inputFocused = true
        } label: {
            HStack {
                Text(text)
                    .font(Type.body)
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
            .glass(.raised, in: Capsule())
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, .lg)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.sm.value) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, .md)
                .padding(.vertical, .md)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.messages.last?.content) { _, _ in
                guard let id = viewModel.messages.last?.id else { return }
                withAnimation(Motion.gentle) { proxy.scrollTo(id, anchor: .bottom) }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: Spacing.sm.value) {
            TextField("Message", text: $viewModel.input, axis: .vertical)
                .focused($inputFocused)
                .lineLimit(1...4)
                .padding(.horizontal, .md)
                .padding(.vertical, .sm)
                .glass(.raised, in: Capsule())
                .clipShape(Capsule())

            Button {
                viewModel.isStreaming ? viewModel.cancel() : viewModel.send()
            } label: {
                Image(systemName: viewModel.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(canSend ? Palette.accent : Palette.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .disabled(!canSend && !viewModel.isStreaming)
        }
        .padding(.horizontal, .md)
        .padding(.bottom, .sm)
    }

    private var canSend: Bool {
        !viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Bubble

private struct MessageBubble: View {
    let message: AIMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content.isEmpty ? "…" : message.content)
                    .font(Type.body)
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, Spacing.sm.value)
                    .padding(.vertical, Spacing.xs.value)
                    .glass(message.role == .user ? .floating : .raised,
                           in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }
}
