import Foundation
import Testing
@testable import DSNYKit

@Suite("Pickup calendar")
struct PickupCalendarTests {
    let calendar = Calendar.newYork
    let schedule = CollectionSchedule.sample // Trash Tue/Thu/Sat, Recycling+Compost Sat, Bulk Tue/Thu

    @Test("Next pickup is today when today is a collection day")
    func today() throws {
        let saturday = calendar.date(2026, 10, 3) // Saturday
        let next = try #require(PickupCalendar.next(schedule, from: saturday, calendar: calendar))
        #expect(calendar.isDate(next.date, inSameDayAs: saturday))
        #expect(next.streams == [.trash, .recycling, .compost])
    }

    @Test("Wraps across the week boundary")
    func wraps() throws {
        let sunday = calendar.date(2026, 10, 4)
        let next = try #require(PickupCalendar.next(schedule, from: sunday, calendar: calendar))
        #expect(Weekday(date: next.date, calendar: calendar) == .tuesday)
        #expect(next.streams == [.trash, .bulk])

        let recycling = try #require(PickupCalendar.nextDate(for: .recycling, in: schedule, from: sunday, calendar: calendar))
        #expect(calendar.isDate(recycling, inSameDayAs: calendar.date(2026, 10, 10)))
    }

    @Test("Upcoming lists only collection days within a week")
    func upcoming() {
        let monday = calendar.date(2026, 10, 5)
        let days = PickupCalendar.upcoming(schedule, from: monday, calendar: calendar)
        #expect(days.map { Weekday(date: $0.date, calendar: calendar) } == [.tuesday, .thursday, .saturday])
    }

    @Test("Relative names")
    func relativeNames() {
        let now = calendar.date(2026, 10, 5)
        #expect(PickupCalendar.relativeDayName(for: now, now: now, calendar: calendar) == "Today")
        #expect(PickupCalendar.relativeDayName(for: calendar.date(2026, 10, 6), now: now, calendar: calendar) == "Tomorrow")
    }

    @Test("Midnights advance one day at a time")
    func midnights() {
        let now = calendar.date(2026, 10, 5, hour: 15)
        let dates = PickupCalendar.midnights(after: now, days: 3, calendar: calendar)
        #expect(dates.count == 3)
        #expect(dates.first == calendar.date(2026, 10, 6, hour: 0))
    }

    @Test("Days until counts calendar days, not 24-hour periods")
    func daysUntil() {
        let lateMonday = calendar.date(2026, 10, 5, hour: 23)
        #expect(PickupCalendar.daysUntil(calendar.date(2026, 10, 5, hour: 1), from: lateMonday, calendar: calendar) == 0)
        #expect(PickupCalendar.daysUntil(calendar.date(2026, 10, 6, hour: 0), from: lateMonday, calendar: calendar) == 1)
        #expect(PickupCalendar.daysUntil(calendar.date(2026, 10, 10), from: lateMonday, calendar: calendar) == 5)
    }

    @Test("Tonight is tomorrow's collection")
    func tonight() throws {
        let monday = calendar.date(2026, 10, 5)
        let pickup = try #require(PickupCalendar.tonight(schedule, from: monday, calendar: calendar))
        #expect(pickup.streams == [.trash, .bulk])
        #expect(Weekday(date: pickup.date, calendar: calendar) == .tuesday)

        let sunday = calendar.date(2026, 10, 4)
        #expect(PickupCalendar.tonight(schedule, from: sunday, calendar: calendar) == nil)
    }

    @Test("Countdown flips to Tonight at 6 PM the day before")
    func countdown() throws {
        let tuesday = try #require(PickupCalendar.next(schedule, from: calendar.date(2026, 10, 5), calendar: calendar))
        #expect(PickupCalendar.countdown(to: tuesday, from: calendar.date(2026, 10, 5, hour: 17), calendar: calendar) == .tomorrow)
        #expect(PickupCalendar.countdown(to: tuesday, from: calendar.date(2026, 10, 5, hour: 18), calendar: calendar) == .tonight)
        #expect(PickupCalendar.countdown(to: tuesday, from: calendar.date(2026, 10, 6, hour: 7), calendar: calendar) == .today)
        #expect(PickupCalendar.countdown(to: tuesday, from: calendar.date(2026, 10, 3), calendar: calendar) == .days(3))
    }

    @Test("Deep links round-trip")
    func deepLinks() throws {
        let id = UUID()
        #expect(DeepLink(url: DeepLink.address(id).url) == .address(id))
        #expect(DeepLink(url: DeepLink.home.url) == .home)
        #expect(DeepLink(url: try #require(URL(string: "dsnypickup://address/not-a-uuid"))) == nil)
        #expect(DeepLink(url: try #require(URL(string: "https://nyc.gov/address/\(id)"))) == nil)
    }

    @Test("Weekday wrap-around")
    func weekdayWrap() {
        #expect(Weekday.sunday.previous == .saturday)
        #expect(Weekday.saturday.next == .sunday)
    }
}
