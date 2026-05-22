import Foundation

/// Server-Sent Events parser. DeepSeek and many Ollama endpoints stream
/// `data: {...}\n\n` framed events. This parses lines into `SSEEvent`s.
///
/// Usage:
///   ```
///   let lines = httpClient.streamLines(request)
///   for try await event in SSEParser.events(from: lines) { ... }
///   ```
public enum SSEParser {
    public struct Event: Sendable, Equatable {
        public let event: String?    // optional `event:` field
        public let data: String      // `data:` payload (may span multiple lines)
        public let id: String?       // optional `id:` field
    }

    public static func events(
        from lines: AsyncThrowingStream<String, any Error>
    ) -> AsyncThrowingStream<Event, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                var event: String? = nil
                var dataBuffer: [String] = []
                var id: String? = nil

                func flush() {
                    guard !dataBuffer.isEmpty || event != nil else { return }
                    let payload = dataBuffer.joined(separator: "\n")
                    continuation.yield(Event(event: event, data: payload, id: id))
                    event = nil
                    dataBuffer.removeAll(keepingCapacity: true)
                    id = nil
                }

                do {
                    for try await raw in lines {
                        // SSE spec: empty line ⇒ dispatch event.
                        if raw.isEmpty {
                            flush()
                            continue
                        }
                        // Comments (start with ":") are ignored per spec.
                        if raw.hasPrefix(":") { continue }

                        if let sep = raw.firstIndex(of: ":") {
                            let field = String(raw[..<sep])
                            var value = String(raw[raw.index(after: sep)...])
                            if value.hasPrefix(" ") { value.removeFirst() }

                            switch field {
                            case "event": event = value
                            case "data":  dataBuffer.append(value)
                            case "id":    id = value
                            default: break // retry, etc. — ignore for now
                            }
                        } else {
                            // Line with no colon is treated as a field name with empty value.
                            // We don't care about those for our use cases.
                            continue
                        }
                    }
                    flush()
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
