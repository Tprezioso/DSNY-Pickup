import AppIntents
import Foundation
import SwiftUI

/// "How do I get rid of a mattress?"
public struct DisposalLookupIntent: AppIntent {
    public static let title: LocalizedStringResource = "How to Get Rid Of"
    public static let description = IntentDescription(
        "Looks up how to dispose of an item in New York City using DSNY's Get Rid Of guide.",
        categoryName: "Get Rid Of",
        searchKeywords: ["dispose", "throw away", "recycle", "donate", "bulk"]
    )

    @Parameter(title: "Item", requestValueDialog: "What do you want to get rid of?")
    public var item: String

    public static var parameterSummary: some ParameterSummary {
        Summary("How to get rid of \(\.$item)")
    }

    public init() {}

    public init(item: String) {
        self.item = item
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
        let service = DisposalGuideService()
        let query = item.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty, let topic = Self.bestMatch(for: query, in: await service.localTopics()) else {
            let answer = String(localized: "I couldn't find \"\(query)\" in DSNY's Get Rid Of guide. Try a simpler name, like \"mattress\" or \"batteries\".")
            return .result(value: answer, dialog: "\(answer)", view: DisposalSnippetView(item: query, category: String(localized: "Get Rid Of"), lines: [answer]))
        }

        let lines: [String]
        if let section = try? await service.section(for: topic) {
            lines = Self.summaryLines(from: section)
        } else {
            lines = [String(localized: "This goes under \(topic.category). Open the DSNY Pickup app for the full instructions.")]
        }

        let answer = lines.joined(separator: " ")
        let spoken = lines.prefix(2).joined(separator: " ")
        return .result(
            value: answer,
            dialog: "\(topic.term): \(spoken)",
            view: DisposalSnippetView(item: topic.term, category: topic.category, lines: lines)
        )
    }

    /// The topic whose term best matches `query`, preferring prefix matches and shorter terms.
    static func bestMatch(for query: String, in topics: [DisposalTopic]) -> DisposalTopic? {
        var best: (topic: DisposalTopic, rank: Int)?
        for topic in topics {
            guard let rank = topic.matchRank(query) else { continue }
            if let current = best {
                let isBetter: Bool = rank < current.rank || (rank == current.rank && topic.term.count < current.topic.term.count)
                if !isBetter { continue }
            }
            best = (topic, rank)
        }
        return best?.topic
    }

    /// The first few readable lines of a section, with Markdown removed so Siri can speak them.
    static func summaryLines(from section: DisposalSection, limit: Int = 4) -> [String] {
        var lines: [String] = []
        for block in section.blocks {
            switch block {
            case .paragraph(let text): lines.append(plainText(text))
            case .bullets(let items): lines.append(contentsOf: items.map { "• " + plainText($0) })
            case .heading: continue
            }
            if lines.count >= limit { break }
        }
        return Array(lines.prefix(limit))
    }

    private static func plainText(_ markdown: String) -> String {
        (try? AttributedString(markdown: markdown)).map { String($0.characters) } ?? markdown
    }
}
