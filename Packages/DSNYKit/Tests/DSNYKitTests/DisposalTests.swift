import Foundation
import Testing
@testable import DSNYKit

@Suite("Get Rid Of guide")
struct DisposalTests {
    @Test("CSV parser handles quoted fields, escaped quotes and CRLF")
    func csv() {
        let rows = CSVParser.rows("a,b\r\n\"x, y\",\"say \"\"hi\"\"\"\n\nlast,row")
        #expect(rows == [["a", "b"], ["x, y", "say \"hi\""], ["last", "row"]])
    }

    @Test("Index splits terms and resolves targets against nyc.gov")
    func index() throws {
        let topics = DisposalIndexParser.topics(fromCSV: try Fixture.string("search-function.csv"))
        #expect(topics.count > 100)

        let toaster = try #require(topics.first { $0.term == "Toasters" })
        #expect(toaster.url.absoluteString == "https://www.nyc.gov/site/dsny/collection/get-rid-of/appliances.page#small-appliances")
        #expect(toaster.anchor == "small-appliances")
        #expect(toaster.pageURL.absoluteString == "https://www.nyc.gov/site/dsny/collection/get-rid-of/appliances.page")
        #expect(toaster.category == "Appliances")
        #expect(toaster.relatedTerms.contains("Blenders"))
        // Double spaces in the source ("Vacuum  cleaners") are collapsed.
        #expect(topics.contains { $0.term == "Vacuum cleaners with cords" })
    }

    @Test("Search matches related terms, ignoring case")
    func matching() {
        let topic = DisposalTopic(term: "Toasters", relatedTerms: ["Blenders"], url: URL(string: "https://www.nyc.gov/x.page")!)
        #expect(topic.matches("toast"))
        #expect(topic.matches("BLEND"))
        #expect(topic.matches(""))
        #expect(!topic.matches("sofa"))
    }

    @Test("Siri lookup picks the closest term and speaks plain text")
    func siriLookup() throws {
        let url = URL(string: "https://www.nyc.gov/x.page")!
        let topics = [
            DisposalTopic(term: "Mattress covers", relatedTerms: [], url: url),
            DisposalTopic(term: "Mattresses", relatedTerms: [], url: url),
            DisposalTopic(term: "Box springs", relatedTerms: ["Mattress foundations"], url: url)
        ]
        #expect(DisposalLookupIntent.bestMatch(for: "mattress", in: topics)?.term == "Mattresses")
        #expect(DisposalLookupIntent.bestMatch(for: "foundation", in: topics)?.term == "Box springs")
        #expect(DisposalLookupIntent.bestMatch(for: "piano", in: topics) == nil)

        let section = DisposalSection(
            title: "Mattresses",
            blocks: [.heading("How"), .paragraph("Put it out for **bulk** collection. [Learn more](https://nyc.gov)"), .bullets(["Bag it", "Seal it"])],
            sourceURL: url
        )
        #expect(DisposalLookupIntent.summaryLines(from: section) == ["Put it out for bulk collection. Learn more", "• Bag it", "• Seal it"])
    }

    @Test("Prefix matches rank ahead of related-term matches")
    func ranking() {
        let url = URL(string: "https://www.nyc.gov/x.page")!
        let toasters = DisposalTopic(term: "Toasters", relatedTerms: ["Blenders"], url: url)
        let ovens = DisposalTopic(term: "Toaster ovens", relatedTerms: [], url: url)
        let blenders = DisposalTopic(term: "Blenders", relatedTerms: ["Toasters"], url: url)
        #expect(toasters.matchRank("toaster") == 0)
        #expect(ovens.matchRank("oven") == 1)
        #expect(blenders.matchRank("toaster") == 2)
        #expect(blenders.matchRank("sofa") == nil)
    }

    @Test("Extracts an h2 section up to the next h2")
    func h2Section() throws {
        let page = URL(string: "https://www.nyc.gov/site/dsny/collection/get-rid-of/appliances.page")!
        let section = try DisposalPageParser.section(html: Fixture.string("appliances.html"), anchor: "small-appliances", pageURL: page)

        #expect(section.title == "Small Appliances")
        #expect(section.sourceURL.fragment == "small-appliances")
        #expect(section.blocks.contains(.heading("Smoke and Carbon Monoxide Detectors")))

        let text = section.blocks.map { block -> String in
            switch block {
            case .paragraph(let text), .heading(let text): text
            case .bullets(let items): items.joined(separator: "\n")
            }
        }.joined(separator: "\n")
        #expect(text.contains("[recycling](https://www.nyc.gov/site/dsny/collection/residents/recycling.page)"))
        #expect(text.contains("**NOTE:**"))
        #expect(!text.contains("Large Appliances"))
    }

    @Test("An h3 section stops at the next h2 or h3 and keeps nested h4s")
    func h3Section() throws {
        let page = URL(string: "https://www.nyc.gov/site/dsny/collection/get-rid-of/appliances.page")!
        let section = try DisposalPageParser.section(html: Fixture.string("appliances.html"), anchor: "cfc", pageURL: page)

        #expect(section.title == "Appliances with CFC")
        #expect(section.blocks.contains(.heading("Appliances with Flammable Refrigerant R600a/R32")))
        #expect(!section.blocks.contains(.heading("Small Appliances")))
    }

    @Test("Large section includes lists with bold text kept as Markdown")
    func bullets() throws {
        let page = URL(string: "https://www.nyc.gov/site/dsny/collection/get-rid-of/appliances.page")!
        let section = try DisposalPageParser.section(html: Fixture.string("appliances.html"), anchor: "large-items", pageURL: page)

        guard case .bullets(let items)? = section.blocks.first(where: { if case .bullets = $0 { true } else { false } }) else {
            Issue.record("Expected a bullet list")
            return
        }
        #expect(items.first?.hasPrefix("Items that are mostly **metal** or **plastic**") == true)
    }

    @Test("Missing anchor falls back to the whole page")
    func wholePage() throws {
        let page = URL(string: "https://www.nyc.gov/site/dsny/collection/get-rid-of/appliances.page")!
        let section = try DisposalPageParser.section(html: Fixture.string("appliances.html"), anchor: "does-not-exist", pageURL: page)
        #expect(section.title == "Appliances")
        #expect(section.blocks.count > 5)
    }

    @Test("Pages without content are reported as invalid")
    func emptyPage() {
        #expect(throws: DSNYError.invalidResponse) {
            try DisposalPageParser.section(html: "<html><body></body></html>", anchor: nil, pageURL: URL(string: "https://www.nyc.gov/x.page")!)
        }
    }
}
