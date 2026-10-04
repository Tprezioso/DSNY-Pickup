import Foundation
import Testing
@testable import DSNYKit

@Suite("Collection schedule")
struct ScheduleTests {
    @Test("Decodes a real DSNY response")
    func decodesResponse() throws {
        let schedule = try ScheduleService.decode(Fixture.data("schedule-125-worth.json"))

        #expect(schedule.formattedAddress == "125 Worth St, New York, NY 10013, USA")
        #expect(schedule.days(for: .trash) == [.tuesday, .thursday, .saturday])
        #expect(schedule.days(for: .recycling) == [.saturday])
        #expect(schedule.days(for: .compost) == [.saturday])
        #expect(schedule.days(for: .bulk) == [.tuesday, .thursday])
        #expect(schedule.residentialRoutingTime?.hasPrefix("Daily") == true)
        #expect(schedule.streams(on: .saturday) == [.trash, .recycling, .compost])
        #expect(schedule.streams(on: .sunday).isEmpty)
    }

    @Test("All-null response means the address wasn't found")
    func notFound() throws {
        #expect(throws: DSNYError.addressNotFound) {
            try ScheduleService.decode(Fixture.data("schedule-not-found.json"))
        }
    }

    static let dayCases: [(String, Set<Weekday>)] = [
        ("Monday,Thursday", [.monday, .thursday]),
        ("monday, THURSDAY ", [.monday, .thursday]),
        ("Mon, Wed, Fri", [.monday, .wednesday, .friday]),
        ("Sunday", [.sunday]),
        ("", []),
        ("Call 311", []),
    ]

    @Test("Day lists tolerate spaces, case, abbreviations and Sunday", arguments: dayCases)
    func parsesDays(text: String, expected: Set<Weekday>) {
        #expect(Weekday.parseList(text) == expected)
    }

    @Test("Unrecognized schedule text is kept for display")
    func unparsedText() {
        let schedule = CollectionSchedule(formattedAddress: "x", rawSchedules: [.bulk: "Call 311", .trash: "Monday"])
        #expect(schedule.unparsedText(for: .bulk) == "Call 311")
        #expect(schedule.unparsedText(for: .trash) == nil)
        #expect(schedule.unparsedText(for: .compost) == nil)
    }

    @Test("Addresses are percent-encoded as a single query value", arguments: [
        "125 Worth St & Centre St, New York",
        "1 Main St #4B, Brooklyn",
        "120-15 31st Ave+, Queens",
    ])
    func encodesAddress(address: String) throws {
        let url = try #require(ScheduleService.url(for: address))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.count == 1)
        #expect(components.queryItems?.first?.value == address)
        #expect(url.absoluteString.contains("%26") || !address.contains("&"))
        #expect(url.absoluteString.contains("%23") || !address.contains("#"))
        #expect(url.absoluteString.contains("%2B") || !address.contains("+"))
    }
}
