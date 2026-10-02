import Foundation

/// "How do I get rid of …?" lookups backed by the same data the nyc.gov Get Rid Of search uses:
/// a CSV index of search terms, and the DSNY category pages it points to.
///
/// The index and every page that's been opened are cached on disk, and a snapshot of the index ships
/// in the bundle, so search works offline and on first launch.
public actor DisposalGuideService {
    public static let indexURL = URL(string: "https://www.nyc.gov/assets/dsny/data/search-function.csv")!

    private let client: HTTPClient
    private let cacheDirectory: URL?
    private var pages: [URL: String] = [:]

    private static let indexFile = "search-function.csv"
    private static let etagFile = "search-function.etag"

    public init(client: HTTPClient = HTTPClient(), cacheDirectory: URL? = DisposalGuideService.defaultCacheDirectory) {
        self.client = client
        self.cacheDirectory = cacheDirectory
    }

    public static var defaultCacheDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appending(path: "DSNYKit/DisposalGuide", directoryHint: .isDirectory)
    }

    // MARK: Index

    /// Topics from the on-disk cache, falling back to the bundled snapshot. Never touches the network.
    public func localTopics() -> [DisposalTopic] {
        if let cached = readCache(Self.indexFile) {
            let topics = DisposalIndexParser.topics(fromCSV: cached)
            if !topics.isEmpty { return topics }
        }
        guard let url = Bundle.module.url(forResource: "search-function", withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return DisposalIndexParser.topics(fromCSV: text)
    }

    /// Downloads the latest index (conditionally, using the cached ETag) and returns it.
    /// Returns `nil` when the cached copy is already current.
    @discardableResult
    public func refreshTopics() async throws -> [DisposalTopic]? {
        var headers: [String: String] = [:]
        if readCache(Self.indexFile) != nil, let etag = readCache(Self.etagFile) {
            headers["If-None-Match"] = etag
        }
        let (data, response) = try await client.get(Self.indexURL, headers: headers)
        if response.statusCode == 304 { return nil }

        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw DSNYError.invalidResponse
        }
        let topics = DisposalIndexParser.topics(fromCSV: text)
        // Don't replace a good cache with an empty or malformed download.
        guard !topics.isEmpty else { throw DSNYError.invalidResponse }

        writeCache(text, to: Self.indexFile)
        if let etag = response.value(forHTTPHeaderField: "ETag") {
            writeCache(etag, to: Self.etagFile)
        }
        return topics
    }

    // MARK: Sections

    /// The page section for `topic`. Prefers a fresh download, falling back to the last cached copy when offline.
    public func section(for topic: DisposalTopic) async throws -> DisposalSection {
        let html = try await page(at: topic.pageURL)
        return try DisposalPageParser.section(html: html, anchor: topic.anchor, pageURL: topic.pageURL)
    }

    private func page(at url: URL) async throws -> String {
        if let html = pages[url] { return html }
        let fileName = Self.cacheFileName(for: url)
        do {
            let (data, _) = try await client.get(url)
            guard let html = String(data: data, encoding: .utf8) else { throw DSNYError.invalidResponse }
            pages[url] = html
            writeCache(html, to: fileName)
            return html
        } catch let error as DSNYError {
            if let html = readCache(fileName) {
                pages[url] = html
                return html
            }
            throw error
        }
    }

    static func cacheFileName(for url: URL) -> String {
        "page-" + url.path().replacingOccurrences(of: "/", with: "_")
    }

    // MARK: Disk cache

    private func readCache(_ name: String) -> String? {
        guard let url = cacheDirectory?.appending(path: name) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private func writeCache(_ text: String, to name: String) {
        guard let directory = cacheDirectory else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? text.write(to: directory.appending(path: name), atomically: true, encoding: .utf8)
    }
}
