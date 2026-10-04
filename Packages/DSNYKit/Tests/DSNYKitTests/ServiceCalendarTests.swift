import Foundation
import Testing
@testable import DSNYKit

@Suite("Service changes")
struct ServiceCalendarTests {
    let calendar = Calendar.newYork
    let schedule = CollectionSchedule.sample // Trash Tue/Thu/Sat, Recycling+Compost Sat, Bulk Tue/Thu

    func thanksgivingWeek() throws -> ServiceCalendar {
        ServiceCalendar(days: try ServiceCalendarService.parse(Fixture.data("service-calendar-thanksgiving.json")))
    }

    @Test("Parses only collections, mapping every known status and keeping unknown ones")
    func parsing() throws {
        let days = try thanksgivingWeek().days
        #expect(days.map(\.dayID) == ["20261124", "20261125", "20261126", "20261127", "20261128", "20261129"])
        #expect(days.map(\.status) == [.onSchedule, .compostSuspended, .suspended, .delayed, .other("SOMETHING NEW"), .notInEffect])
        #expect(days[2].exceptionName == "Thanksgiving Day 2026")
    }

    @Test("Malformed responses throw invalidResponse")
    func malformed() {
        #expect(throws: DSNYError.invalidResponse) { try ServiceCalendarService.parse(Data("{\"nope\":1}".utf8)) }
    }

    @Test("Statuses cancel the right streams")
    func cancelled() {
        #expect(CollectionStatus.suspended.cancelledStreams == Set(CollectionStream.allCases))
        #expect(CollectionStatus.compostSuspended.cancelledStreams == [.compost])
        #expect(CollectionStatus.trashAndRecyclingSuspended.cancelledStreams == [.trash, .recycling, .bulk])
        #expect(CollectionStatus.delayed.cancelledStreams.isEmpty)
        #expect(CollectionStatus.delayed.isServiceChange)
        #expect(!CollectionStatus.other("SOMETHING NEW").isServiceChange)
        #expect(!CollectionStatus.notInEffect.isServiceChange)
    }

    @Test("A suspended Thursday is skipped; next pickup moves to Saturday")
    func holidaySkipsDay() throws {
        let service = try thanksgivingWeek()
        let wednesday = calendar.date(2026, 11, 25)

        let next = try #require(PickupCalendar.next(schedule, from: wednesday, service: service, calendar: calendar))
        #expect(Weekday(date: next.date, calendar: calendar) == .saturday)

        let change = try #require(PickupCalendar.nextChange(schedule, from: wednesday, service: service, calendar: calendar))
        #expect(Weekday(date: change.date, calendar: calendar) == .thursday)
        #expect(change.isFullyCancelled)
        #expect(change.cancelled == [.trash, .bulk])
        #expect(change.notice?.headline == "Thanksgiving Day: No Collection")

        let tonight = try #require(PickupCalendar.tonight(schedule, from: wednesday, service: service, calendar: calendar))
        #expect(tonight.isFullyCancelled)
    }

    @Test("Delays keep streams but carry a notice")
    func delay() throws {
        let service = ServiceCalendar(days: [ServiceDay(dayID: "20261124", statusValue: "DELAYED")])
        let tuesday = calendar.date(2026, 11, 24)
        let next = try #require(PickupCalendar.next(schedule, from: tuesday, service: service, calendar: calendar))
        #expect(next.streams == [.trash, .bulk])
        #expect(next.notice?.isDelay == true)
        #expect(next.notice?.headline == "Collections Delayed")
    }

    @Test("Partial suspensions remove only the affected streams")
    func partial() throws {
        let service = ServiceCalendar(days: [ServiceDay(dayID: "20261128", statusValue: "COMPOST SUSPENDED")])
        let saturday = calendar.date(2026, 11, 28)
        let next = try #require(PickupCalendar.next(schedule, from: saturday, service: service, calendar: calendar))
        #expect(next.streams == [.trash, .recycling])
        #expect(next.cancelled == [.compost])
    }

    @Test("Request uses MM/dd/yyyy and the subscription key header")
    func request() throws {
        let url = try #require(ServiceCalendarService.requestURL(from: calendar.date(2026, 11, 3), days: 60, calendar: calendar))
        #expect(url.absoluteString == "https://api.nyc.gov/public/api/GetCalendar?fromdate=11/03/2026&todate=01/02/2027")
    }

    @Test("Cache round-trips through disk")
    func cache() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "service-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(ServiceCalendarService.cached(at: url) == .empty)

        let calendar = try thanksgivingWeek()
        let data = try JSONEncoder().encode(calendar)
        try data.write(to: url)
        #expect(ServiceCalendarService.cached(at: url).days == calendar.days)
    }
}
