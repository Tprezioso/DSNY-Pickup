import Foundation

/// Errors surfaced to the UI. Each case has a user-facing description and a recovery hint.
public enum DSNYError: Error, Sendable, Equatable, LocalizedError {
    /// The device is offline or the request timed out.
    case offline
    /// DSNY couldn't match the address to a collection route.
    case addressNotFound
    /// The server answered with an unexpected status code.
    case server(status: Int)
    /// The response couldn't be decoded or parsed.
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .offline: String(localized: "You're offline")
        case .addressNotFound: String(localized: "Address not found")
        case .server: String(localized: "DSNY isn't responding")
        case .invalidResponse: String(localized: "Something went wrong")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .offline: String(localized: "Check your connection and try again.")
        // DSNY answers an outage the same way as an unknown address, so mention both.
        case .addressNotFound: String(localized: "Try a full street address in the five boroughs, like \"125 Worth St, Manhattan\". If the address is right, DSNY's lookup may be temporarily down. Try again later.")
        case .server: String(localized: "The city's service may be down. Try again in a few minutes.")
        case .invalidResponse: String(localized: "DSNY returned data the app didn't understand. Try again later.")
        }
    }

    public var systemImage: String {
        switch self {
        case .offline: "wifi.slash"
        case .addressNotFound: "mappin.slash"
        case .server, .invalidResponse: "exclamationmark.icloud"
        }
    }
}

/// Minimal transport abstraction so services can be tested with canned responses.
public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

/// Thin async wrapper over `URLSession` with timeouts, one retry for transient failures,
/// and conversion of transport errors to `DSNYError`.
public struct HTTPClient: Sendable {
    private let transport: any HTTPTransport
    private let timeout: TimeInterval
    private let retryDelay: Duration

    public init(transport: any HTTPTransport = URLSession.shared, timeout: TimeInterval = 15, retryDelay: Duration = .milliseconds(800)) {
        self.transport = transport
        self.timeout = timeout
        self.retryDelay = retryDelay
    }

    /// Builds a URL from a base and query items, letting `URLComponents` handle escaping
    /// (so addresses containing `&`, `#` or `+` survive intact).
    public static func url(_ base: String, query: [String: String] = [:]) -> URL? {
        guard var components = URLComponents(string: base) else { return nil }
        if !query.isEmpty {
            components.queryItems = query.sorted(by: { $0.key < $1.key }).map { URLQueryItem(name: $0.key, value: $0.value) }
            // `URLComponents` leaves `+` unescaped, which many servers read as a space.
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        }
        return components.url
    }

    /// Performs a GET and returns the body and HTTP response. Non-2xx statuses other than 304 throw.
    public func get(_ url: URL, headers: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue("application/json, text/csv, text/html;q=0.9, */*;q=0.8", forHTTPHeaderField: "Accept")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        do {
            return try await perform(request)
        } catch let error as DSNYError where error.isTransient {
            try await Task.sleep(for: retryDelay)
            return try await perform(request)
        }
    }

    /// GETs and decodes JSON.
    public func getJSON<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, _) = try await get(url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw DSNYError.invalidResponse
        }
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw DSNYError.offline
        }

        guard let http = response as? HTTPURLResponse else { throw DSNYError.invalidResponse }
        guard (200..<300).contains(http.statusCode) || http.statusCode == 304 else {
            throw DSNYError.server(status: http.statusCode)
        }
        return (data, http)
    }
}

extension DSNYError {
    /// Worth one retry: dropped connections and 5xx/429 responses.
    var isTransient: Bool {
        switch self {
        case .offline: true
        case .server(let status): status == 429 || status >= 500
        case .addressNotFound, .invalidResponse: false
        }
    }
}
