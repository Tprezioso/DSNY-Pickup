import Foundation

/// One searchable entry from DSNY's "Get Rid Of" index, e.g. "Toasters" → appliances.page#small-appliances.
public struct DisposalTopic: Sendable, Hashable, Identifiable {
    /// The search term shown to the user.
    public let term: String
    /// The other terms from the same index row, used for matching and "also known as" text.
    public let relatedTerms: [String]
    /// Absolute URL of the DSNY page, including the section fragment when there is one.
    public let url: URL

    public var id: String { "\(term)|\(url.absoluteString)" }

    public init(term: String, relatedTerms: [String], url: URL) {
        self.term = term
        self.relatedTerms = relatedTerms
        self.url = url
    }

    /// The page's section anchor (the URL fragment), if any.
    public var anchor: String? { url.fragment(percentEncoded: false) }

    /// The page URL without the fragment, used to fetch and cache the page once for all its sections.
    public var pageURL: URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        return components?.url ?? url
    }

    /// A readable category name derived from the page slug, e.g. "get-rid-of/large-items.page" → "Large Items".
    public var category: String {
        let slug = pageURL.deletingPathExtension().lastPathComponent
        if let title = Self.categoryTitles[slug] { return title }
        return slug.split(separator: "-").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }

    /// DSNY's page titles for slugs that lose punctuation when split on hyphens.
    private static let categoryTitles: [String: String] = [
        "clothing-household-fabrics-accessories": "Clothing, Household Fabrics, & Accessories",
        "furniture-mattresses": "Furniture, Mattresses, & Rugs",
        "gas-cylinders-fire-extinguishers": "Gas Cylinders & Fire Extinguishers",
        "ink-and-toner-cartridges": "Ink & Toner Cartridges",
        "metal-glass-plastic-cartons": "Metal, Glass, Plastic, & Cartons",
        "mixed-paper-cardboard": "Mixed Paper & Cardboard",
        "oil-grease": "Oils, Grease, & Fats",
        "plant-yard-waste": "Plant, Leaf, & Yard Waste",
        "spurs": "Get Rid of the Spurs"
    ]

    /// How well the topic matches `query`, or `nil` for no match. Lower is better:
    /// 0 = term starts with the query, 1 = term contains it, 2 = only a related term matches.
    public func matchRank(_ query: String) -> Int? {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return 1 }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        if term.range(of: query, options: options.union(.anchored)) != nil { return 0 }
        if term.range(of: query, options: options) != nil { return 1 }
        if relatedTerms.contains(where: { $0.range(of: query, options: options) != nil }) { return 2 }
        return nil
    }

    /// Case- and diacritic-insensitive match against the term and its related terms.
    public func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return ([term] + relatedTerms).contains { $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }
}

/// A parsed section of a DSNY "Get Rid Of" page.
public struct DisposalSection: Sendable, Equatable {
    public let title: String
    public let blocks: [Block]
    public let sourceURL: URL

    public init(title: String, blocks: [Block], sourceURL: URL) {
        self.title = title
        self.blocks = blocks
        self.sourceURL = sourceURL
    }

    public enum Block: Sendable, Equatable, Hashable {
        /// A paragraph rendered from Markdown, so inline links and bold text survive.
        case paragraph(String)
        /// A sub-heading inside the section.
        case heading(String)
        /// A bulleted list; each item is Markdown.
        case bullets([String])
    }
}
