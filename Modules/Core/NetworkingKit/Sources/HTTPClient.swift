import Foundation

/// Minimal HTTP client. We deliberately avoid Alamofire — `URLSession` +
/// `async/await` is enough and ships with the OS.
///
/// Streaming is first-class because every AI provider needs it.
public actor HTTPClient {
    public struct Config: Sendable {
        public var baseURL: URL?
        public var defaultHeaders: [String: String]
        public var timeout: TimeInterval

        public init(
            baseURL: URL? = nil,
            defaultHeaders: [String: String] = [:],
            timeout: TimeInterval = 60
        ) {
            self.baseURL = baseURL
            self.defaultHeaders = defaultHeaders
            self.timeout = timeout
        }
    }

    public enum HTTPError: Error, Sendable, Equatable {
        case badStatus(Int, body: String?)
        case transport(String)
        case invalidURL
    }

    private let config: Config
    private let session: URLSession

    public init(config: Config = .init()) {
        self.config = config
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = config.timeout
        cfg.waitsForConnectivity = true
        self.session = URLSession(configuration: cfg)
    }

    public func send<T: Decodable & Sendable>(
        _ request: HTTPRequest,
        as type: T.Type
    ) async throws -> T {
        let urlRequest = try buildRequest(request)
        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func sendRaw(_ request: HTTPRequest) async throws -> Data {
        let urlRequest = try buildRequest(request)
        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        return data
    }

    /// Stream the response body as a sequence of UTF-8 lines. Backbone for
    /// Server-Sent-Events (Ollama, DeepSeek). Empty lines are preserved so
    /// the caller can implement SSE event boundaries.
    public func streamLines(_ request: HTTPRequest) -> AsyncThrowingStream<String, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let urlRequest = try buildRequest(request)
                    let (bytes, response) = try await session.bytes(for: urlRequest)
                    try validateHeader(response: response)
                    for try await line in bytes.lines {
                        continuation.yield(line)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Private

    private func buildRequest(_ request: HTTPRequest) throws -> URLRequest {
        let url: URL
        if let base = config.baseURL, !request.path.contains("://") {
            url = base.appending(path: request.path)
        } else if let absolute = URL(string: request.path) {
            url = absolute
        } else {
            throw HTTPError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = request.method.rawValue
        for (k, v) in config.defaultHeaders { req.setValue(v, forHTTPHeaderField: k) }
        for (k, v) in request.headers       { req.setValue(v, forHTTPHeaderField: k) }
        req.httpBody = request.body
        return req
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.transport("Non-HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            throw HTTPError.badStatus(http.statusCode, body: String(data: data, encoding: .utf8))
        }
    }

    private func validateHeader(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.transport("Non-HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            throw HTTPError.badStatus(http.statusCode, body: nil)
        }
    }
}

public struct HTTPRequest: Sendable {
    public enum Method: String, Sendable { case GET, POST, PUT, PATCH, DELETE }

    public let path: String
    public let method: Method
    public let headers: [String: String]
    public let body: Data?

    public init(
        path: String,
        method: Method = .GET,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
    }

    public static func json<T: Encodable>(
        path: String,
        method: Method = .POST,
        body: T,
        headers: [String: String] = [:]
    ) throws -> HTTPRequest {
        var h = headers
        h["Content-Type"] = "application/json"
        let data = try JSONEncoder().encode(body)
        return HTTPRequest(path: path, method: method, headers: h, body: data)
    }
}
