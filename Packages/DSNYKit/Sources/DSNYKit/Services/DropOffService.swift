import Foundation

/// Drop-off locations from NYC Open Data (Socrata). No app token is needed at this request volume.
public struct DropOffService: Sendable {
    private let client: HTTPClient

    public init(client: HTTPClient = HTTPClient()) {
        self.client = client
    }

    static func url(for kind: DropOffSite.Kind) -> URL? {
        HTTPClient.url("https://data.cityofnewyork.us/resource/\(kind.datasetID).json", query: ["$limit": "2000"])
    }

    /// All sites of one kind.
    public func sites(_ kind: DropOffSite.Kind) async throws -> [DropOffSite] {
        guard let url = Self.url(for: kind) else { throw DSNYError.invalidResponse }
        let rows = try await client.getJSON([DropOffRow].self, from: url)
        return Self.sites(from: rows, kind: kind)
    }

    static func sites(from rows: [DropOffRow], kind: DropOffSite.Kind) -> [DropOffSite] {
        var seen = Set<String>()
        return rows
            .compactMap { $0.site(kind: kind) }
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Decodes a raw response body. Exposed for tests.
    static func decode(_ data: Data, kind: DropOffSite.Kind) throws -> [DropOffSite] {
        sites(from: try JSONDecoder().decode([DropOffRow].self, from: data), kind: kind)
    }
}
