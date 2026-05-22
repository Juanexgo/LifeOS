import Foundation
import Observation
import AIKit

/// Drives the Assistant chat. Holds message history, streams from the
/// `AIRouter`, and exposes a single `send(_:)` entry point.
///
/// `@Observable` + `@MainActor` — UI reads it directly. The actual streaming
/// runs in detached `Task`s so the main actor doesn't block.
@MainActor
@Observable
public final class AssistantViewModel {
    public private(set) var messages: [AIMessage] = []
    public private(set) var isStreaming: Bool = false
    public private(set) var availabilityHint: String = "Checking on-device AI…"

    public var input: String = ""

    private let router: AIRouter
    private var activeTask: Task<Void, Never>?

    public init(router: AIRouter) {
        self.router = router
        Task { await refreshAvailability() }
    }

    /// Send the current `input` as a user message.
    public func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        let userMessage = AIMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        input = ""

        // Optimistically append an empty assistant message we'll stream into.
        var assistantMessage = AIMessage(role: .assistant, content: "")
        messages.append(assistantMessage)

        isStreaming = true
        activeTask = Task { [router] in
            do {
                let request = AIRequest(
                    messages: self.messages.filter { $0.role != .assistant || !$0.content.isEmpty },
                    privacyClass: .general,
                    required: [.streaming]
                )
                let stream = try await router.stream(request)
                for try await chunk in stream {
                    assistantMessage = AIMessage(
                        id: assistantMessage.id,
                        role: .assistant,
                        content: assistantMessage.content + chunk.delta,
                        createdAt: assistantMessage.createdAt
                    )
                    if let idx = self.messages.lastIndex(where: { $0.id == assistantMessage.id }) {
                        self.messages[idx] = assistantMessage
                    }
                }
            } catch {
                // Replace the empty assistant message with a polite error.
                if let idx = self.messages.lastIndex(where: { $0.id == assistantMessage.id }) {
                    self.messages[idx] = AIMessage(
                        id: assistantMessage.id,
                        role: .assistant,
                        content: friendlyMessage(for: error),
                        createdAt: assistantMessage.createdAt
                    )
                }
            }
            self.isStreaming = false
        }
    }

    public func cancel() {
        activeTask?.cancel()
        activeTask = nil
        isStreaming = false
    }

    public func clear() {
        cancel()
        messages.removeAll()
    }

    // MARK: - Private

    private func refreshAvailability() async {
        let ids = await router.registered()
        if ids.isEmpty {
            availabilityHint = "No AI providers configured."
        } else {
            availabilityHint = "On-device AI is the default. Cloud is opt-in."
        }
    }

    private func friendlyMessage(for error: any Error) -> String {
        if let aiError = error as? AIError {
            switch aiError {
            case .noProviderRegistered:
                return "No AI providers are registered yet."
            case .noCapableProvider:
                return "None of your providers can satisfy this request."
            case .providerUnavailable:
                return "The selected provider isn't ready. Try again, or set up Apple Intelligence in Settings."
            case .personalRequestEscalationBlocked:
                return "This request was kept on-device, but no on-device provider is available."
            case .malformedResponse(let detail):
                return "The provider returned something I couldn't read.\n\(detail)"
            case .cancelled:
                return "Stopped."
            }
        }
        return "Something went wrong: \(error.localizedDescription)"
    }
}
