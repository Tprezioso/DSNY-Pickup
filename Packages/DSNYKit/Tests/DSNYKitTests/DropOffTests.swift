import Foundation
import Testing
@testable import DSNYKit

@Suite("Drop-off sites")
struct DropOffTests {
    @Test("Special waste rows use GeoJSON points and borough codes")
    func specialWaste() throws {
        let sites = try DropOffService.decode(Fixture.data("special-waste.json"), kind: .specialWaste)
        let site = try #require(sites.first { $0.address.hasPrefix("74 Pike Slip") })
        #expect(site.borough == "Manhattan")
        #expect(site.address == "74 Pike Slip, New York, 10002")
        #expect(abs(site.latitude - 40.7099) < 0.001)
        #expect(abs(site.longitude + 73.9923) < 0.001)
    }

    @Test("Electronics rows decode names and string coordinates")
    func electronics() throws {
        let sites = try DropOffService.decode(Fixture.data("electronics.json"), kind: .electronics)
        #expect(!sites.isEmpty)
        #expect(sites.allSatisfy { !$0.name.isEmpty && $0.latitude > 40 && $0.longitude < -73 })
    }

    @Test("Food scrap rows include hours and websites")
    func foodScraps() throws {
        let sites = try DropOffService.decode(Fixture.data("food-scraps.json"), kind: .foodScraps)
        let site = try #require(sites.first { $0.name == "Dag Hammarskjold Plaza Greenmarket" })
        #expect(site.hours?.contains("Wednesday") == true)
        #expect(site.website?.absoluteString == "https://grownyc.org/compost")
    }

    @Test("Rows without coordinates are skipped")
    func skipsMissingCoordinates() throws {
        let sites = try DropOffService.decode(Data(#"[{"name":"Nowhere"}]"#.utf8), kind: .specialWaste)
        #expect(sites.isEmpty)
    }
}
