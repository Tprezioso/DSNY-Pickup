import Foundation

/// Holidays, snow delays and other collection changes from the NYC 311 Public API
/// (`api.nyc.gov/public/api/GetCalendar`, free key from api-portal.nyc.gov).
///
/// Only the app fetches; the result is cached in the app group so widgets, intents and
/// reminders read it without a key or network.
public struct ServiceCalendarService: Sendable {
    static let endpoint = "https://api.nyc.gov/public/api/GetCalendar"
    /// The API allows at most 90 days per request.
    public static let lookaheadDays = 60

    private let client: HTTPClient
    private let apiKey: String
    private let cacheURL: URL?

    public init(apiKey: String, client: HTTPClient = HTTPClient(), cacheURL: URL? = ServiceCalendarService.defaultCacheURL) {
        self.apiKey = apiKey
        self.client = client
        self.cacheURL = cacheURL
    }

    public static var defaultCacheURL: URL? {
        SharedModelContainer.groupDirectory?.appending(path: "service-calendar.json")
    }

    /// Downloads today through `lookaheadDays` and caches it. Returns the fresh calendar.
    @discardableResult
    public func refresh(from now: Date = .now, calendar: Calendar = .current) async throws -> ServiceCalendar {
        guard let url = Self.requestURL(from: now, days: Self.lookaheadDays, calendar: calendar) else { throw DSNYError.invalidResponse }
        let (data, _) = try await client.get(url, headers: ["Ocp-Apim-Subscription-Key": apiKey])
        let result = ServiceCalendar(days: try Self.parse(data), fetchedAt: now)
        Self.write(result, to: cacheURL)
        return result
    }

    /// The last downloaded calendar, or `.empty`. Never touches the network.
    public static func cached(at url: URL? = defaultCacheURL) -> ServiceCalendar {
        guard let url, let data = try? Data(contentsOf: url),
              let calendar = try? JSONDecoder().decode(ServiceCalendar.self, from: data) else { return .empty }
        return calendar
    }

    static func parse(_ data: Data) throws -> [ServiceDay] {
        do {
            return try JSONDecoder().decode(ServiceCalendarResponse.self, from: data).serviceDays()
        } catch {
            throw DSNYError.invalidResponse
        }
    }

    static func requestURL(from now: Date, days: Int, calendar: Calendar) -> URL? {
        guard let end = calendar.date(byAdding: .day, value: days, to: now) else { return nil }
        return HTTPClient.url(endpoint, query: ["fromdate": apiDate(now, calendar: calendar), "todate": apiDate(end, calendar: calendar)])
    }

    /// "MM/dd/yyyy", the format the API expects.
    static func apiDate(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%02d/%02d/%04d", parts.month ?? 0, parts.day ?? 0, parts.year ?? 0)
    }

    private static func write(_ calendar: ServiceCalendar, to url: URL?) {
        guard let url, let data = try? JSONEncoder().encode(calendar) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
