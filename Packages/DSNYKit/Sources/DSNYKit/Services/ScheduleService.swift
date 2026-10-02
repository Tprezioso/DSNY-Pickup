import Foundation

/// Looks up curbside collection days for an address.
///
/// Uses the same JSON endpoint as DSNY's own "Collection Schedule" lookup on nyc.gov.
/// It isn't formally documented, so all access is kept here to make it easy to replace
/// (e.g. with NYC Geoclient plus the Open Data frequency datasets).
public struct ScheduleService: Sendable {
    static let endpoint = "https://a827-donatenyc.nyc.gov/DSNYGeoCoder/api/DSNYCollection/CollectionSchedule"

    private let client: HTTPClient

    public init(client: HTTPClient = HTTPClient()) {
        self.client = client
    }

    /// The request URL for `address`.
    static func url(for address: String) -> URL? {
        HTTPClient.url(endpoint, query: ["address": address])
    }

    /// Fetches the schedule for a free-form address. Throws `DSNYError.addressNotFound` when DSNY can't match it.
    public func schedule(for address: String) async throws -> CollectionSchedule {
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty, let url = Self.url(for: address) else { throw DSNYError.addressNotFound }
        let response = try await client.getJSON(CollectionScheduleResponse.self, from: url)
        guard let schedule = response.schedule() else { throw DSNYError.addressNotFound }
        return schedule
    }

    /// Decodes a raw response body. Exposed for tests and previews.
    static func decode(_ data: Data) throws -> CollectionSchedule {
        let response = try JSONDecoder().decode(CollectionScheduleResponse.self, from: data)
        guard let schedule = response.schedule() else { throw DSNYError.addressNotFound }
        return schedule
    }
}
