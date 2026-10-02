import Foundation
import SwiftSoup

/// Parses DSNY's `search-function.csv` index ("Search Term,Target").
enum DisposalIndexParser {
    static let siteBase = URL(string: "https://www.nyc.gov")!

    static func topics(fromCSV text: String) -> [DisposalTopic] {
        var seen = Set<String>()
        var topics: [DisposalTopic] = []

        // Skip the header row.
        for row in CSVParser.rows(text).dropFirst() {
            guard row.count >= 2 else { continue }
            let target = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !target.isEmpty, let url = URL(string: target, relativeTo: siteBase)?.absoluteURL else { continue }

            let terms = row[0]
                .split(separator: ",")
                .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
                .filter { !$0.isEmpty }
                // The index mixes "Toasters" and "hand-held vacuums"; capitalize for display.
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }

            for term in terms {
                let topic = DisposalTopic(term: term, relatedTerms: terms.filter { $0 != term }, url: url)
                if seen.insert(topic.id.lowercased()).inserted {
                    topics.append(topic)
                }
            }
        }
        return topics.sorted { $0.term.localizedStandardCompare($1.term) == .orderedAscending }
    }
}

/// A small RFC 4180 CSV reader: quoted fields, escaped quotes (`""`), and CRLF or LF line endings.
enum CSVParser {
    static func rows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var iterator = text.makeIterator()
        var pending: Character? = nil

        func endField() { row.append(field); field = "" }
        func endRow() {
            endField()
            if !(row.count == 1 && row[0].isEmpty) { rows.append(row) }
            row = []
        }

        while let char = pending ?? iterator.next() {
            pending = nil
            if inQuotes {
                if char == "\"" {
                    let next = iterator.next()
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        inQuotes = false
                        pending = next
                    }
                } else {
                    field.append(char)
                }
            } else {
                switch char {
                case "\"": inQuotes = true
                case ",": endField()
                // Swift treats "\r\n" as a single Character.
                case "\n", "\r\n", "\r": endRow()
                default: field.append(char)
                }
            }
        }
        if !field.isEmpty || !row.isEmpty { endRow() }
        return rows
    }
}

/// Extracts a section of a DSNY "Get Rid Of" page as Markdown blocks.
enum DisposalPageParser {
    /// Returns the section headed by the element with `id == anchor`, or the whole page body when `anchor` is nil
    /// or missing from the page. Throws `DSNYError.invalidResponse` if the page has no recognizable content.
    static func section(html: String, anchor: String?, pageURL: URL) throws -> DisposalSection {
        let document: Document
        do {
            document = try SwiftSoup.parse(html, pageURL.absoluteString)
        } catch {
            throw DSNYError.invalidResponse
        }

        if let anchor, !anchor.isEmpty,
           let target = try? document.getElementById(anchor),
           let heading = headingContaining(target) {
            let level = headingLevel(heading) ?? 6
            var blocks: [DisposalSection.Block] = []
            var sibling = try? heading.nextElementSibling()
            while let element = sibling {
                if let siblingLevel = headingLevel(element), siblingLevel <= level { break }
                blocks += self.blocks(for: element, base: pageURL)
                sibling = try? element.nextElementSibling()
            }
            let title = (try? heading.text()).flatMap { $0.isEmpty ? nil : $0 } ?? anchor
            return DisposalSection(title: title, blocks: blocks, sourceURL: pageURL.appendingFragment(anchor))
        }

        // Whole page: DSNY pages keep their body in `.about-description`.
        guard let container = try? document.select(".about-description").first() ?? document.body() else {
            throw DSNYError.invalidResponse
        }
        var title = (try? document.select("h1").first()?.text()) ?? ""
        var blocks: [DisposalSection.Block] = []
        for child in container.children() {
            if child.tagName() == "h1" {
                title = (try? child.text()) ?? title
                continue
            }
            blocks += self.blocks(for: child, base: pageURL)
        }
        guard !blocks.isEmpty else { throw DSNYError.invalidResponse }
        return DisposalSection(title: title, blocks: blocks, sourceURL: pageURL)
    }

    // MARK: - Helpers

    private static func headingLevel(_ element: Element) -> Int? {
        let tag = element.tagName().lowercased()
        guard tag.count == 2, tag.first == "h", let level = tag.last.flatMap({ Int(String($0)) }), (1...6).contains(level) else { return nil }
        return level
    }

    /// DSNY anchors are empty `<a id>` tags inside headings; also accept an id placed on the heading itself.
    private static func headingContaining(_ element: Element) -> Element? {
        if headingLevel(element) != nil { return element }
        var parent = element.parent()
        while let current = parent {
            if headingLevel(current) != nil { return current }
            parent = current.parent()
        }
        return nil
    }

    private static func blocks(for element: Element, base: URL) -> [DisposalSection.Block] {
        switch element.tagName().lowercased() {
        case "p":
            let text = markdown(element, base: base)
            return text.isEmpty ? [] : [.paragraph(text)]
        case "ul", "ol":
            let items = element.children()
                .filter { $0.tagName().lowercased() == "li" }
                .map { markdown($0, base: base) }
                .filter { !$0.isEmpty }
            return items.isEmpty ? [] : [.bullets(items)]
        case "h2", "h3", "h4", "h5", "h6":
            let text = (try? element.text()) ?? ""
            return text.isEmpty ? [] : [.heading(text)]
        case "div", "section":
            return element.children().flatMap { blocks(for: $0, base: base) }
        default:
            return []
        }
    }

    /// Converts inline HTML to Markdown, keeping links (absolute), bold and italics.
    static func markdown(_ element: Element, base: URL) -> String {
        inline(element, base: base)
            .replacingOccurrences(of: "[ \\t\\u{00A0}]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " *\\n *", with: "\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func inline(_ node: Node, base: URL) -> String {
        if let text = node as? TextNode {
            return escape(text.text())
        }
        guard let element = node as? Element else { return "" }
        let inner = element.getChildNodes().map { inline($0, base: base) }.joined()

        switch element.tagName().lowercased() {
        case "a":
            let label = inner.trimmingCharacters(in: .whitespaces)
            guard let href = try? element.attr("href"), !href.isEmpty, !label.isEmpty,
                  let url = URL(string: href, relativeTo: base)?.absoluteURL else { return inner }
            return wrap(inner, prefix: "[", suffix: "](\(url.absoluteString))")
        case "strong", "b":
            return wrap(inner, prefix: "**", suffix: "**")
        case "em", "i":
            return wrap(inner, prefix: "*", suffix: "*")
        case "br":
            return "\n"
        default:
            return inner
        }
    }

    /// Wraps the trimmed text in Markdown delimiters, keeping surrounding spaces outside
    /// (`<strong>metal </strong>` → `**metal** `), since Markdown ignores `**metal **`.
    private static func wrap(_ text: String, prefix: String, suffix: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return text }
        let leading = text.prefix(while: \.isWhitespace)
        let trailing = String(text.reversed().prefix(while: \.isWhitespace))
        return "\(leading)\(prefix)\(trimmed)\(suffix)\(trailing)"
    }

    private static func escape(_ text: String) -> String {
        var result = ""
        for char in text {
            if "*_[]`\\".contains(char) { result.append("\\") }
            result.append(char)
        }
        return result
    }
}

extension URL {
    func appendingFragment(_ fragment: String) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.fragment = fragment
        return components?.url ?? self
    }
}
