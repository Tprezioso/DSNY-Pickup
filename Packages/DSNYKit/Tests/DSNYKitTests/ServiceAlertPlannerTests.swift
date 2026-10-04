import Foundation
import Testing
@testable import DSNYKit

@Suite("Service alerts")
struct ServiceAlertPlannerTests {
    let calendar = Calendar.newYork
    let home = AddressSnapshot(id: UUID(), name: "Home", shortAddress: "125 Worth St", schedule: .sample) // Trash/Bulk Tue+Thu, all Sat
    let office = AddressSnapshot(
        id: UUID(), name: "Office", shortAddress: "253 Broadway",
        schedule: CollectionSchedule(formattedAddress: "253 Broadway", rawSchedules: [.trash: "Monday,Thursday", .recycling: "Thursday"])
    )
    let thanksgiving = ServiceCalendar(days: [ServiceDay(dayID: "20261126", statusValue: "SUSPENDED", exceptionName: "Thanksgiving Day")], fetchedAt: .now)

    @Test("Heads-up at 10 AM two days before, one alert covering every affected address")
    func headsUp() throws {
        let alerts = ServiceAlertPlanner.headsUps(for: [home, office], service: thanksgiving, now: calendar.date(2026, 11, 20), calendar: calendar)
        let alert = try #require(alerts.first)
        #expect(alerts.count == 1)
        #expect(alert.fireDate == calendar.date(2026, 11, 24, hour: 10))
        #expect(alert.title == "Thursday: Thanksgiving Day: No Collection")
        #expect(alert.body.contains("No Trash and Bulk Items at Home. Keep your bins in."))
        #expect(alert.body.contains("No Trash and Recycling at Office."))
        #expect(alert.identifier.hasPrefix("alert.headsup.20261126"))
    }

    @Test("No heads-up once its time has passed, or when no pickup is affected")
    func headsUpSkipped() {
        #expect(ServiceAlertPlanner.headsUps(for: [home], service: thanksgiving, now: calendar.date(2026, 11, 25), calendar: calendar).isEmpty)
        let mondayOnly = AddressSnapshot(id: UUID(), name: "x", shortAddress: "x", schedule: CollectionSchedule(formattedAddress: "x", rawSchedules: [.trash: "Monday"]))
        #expect(ServiceAlertPlanner.headsUps(for: [mondayOnly], service: thanksgiving, now: calendar.date(2026, 11, 20), calendar: calendar).isEmpty)
    }

    @Test("Breaking alerts only for newly published changes within two days")
    func breaking() throws {
        let morning = calendar.date(2026, 12, 3, hour: 7) // Thursday
        let before = ServiceCalendar(days: [ServiceDay(dayID: "20261203", statusValue: "ON SCHEDULE")], fetchedAt: calendar.date(2026, 12, 3, hour: 4))
        let snow = ServiceCalendar(days: [ServiceDay(dayID: "20261203", statusValue: "DELAYED")], fetchedAt: morning)

        let alerts = ServiceAlertPlanner.breakingAlerts(old: before, new: snow, for: [home], now: morning, calendar: calendar)
        let alert = try #require(alerts.first)
        #expect(alert.title == "Today: Collections Delayed")
        #expect(alert.body.contains("may run late"))
        #expect(alert.fireDate > morning)

        // Already known: no repeat.
        #expect(ServiceAlertPlanner.breakingAlerts(old: snow, new: snow, for: [home], now: morning, calendar: calendar).isEmpty)
        // First download after install: stay quiet.
        #expect(ServiceAlertPlanner.breakingAlerts(old: .empty, new: snow, for: [home], now: morning, calendar: calendar).isEmpty)
    }

    @Test("Alerts get first claim on the notification budget")
    func budget() async throws {
        let center = FakeNotificationCenter()
        let scheduler = ReminderScheduler(center: center)
        let now = calendar.date(2026, 11, 2)
        let plans = (0..<10).map { _ in ReminderPlan(addressID: UUID(), addressName: "x", schedule: .sample, isEnabled: true, minutesAfterMidnight: 19 * 60, timing: .dayBefore, streams: Set(CollectionStream.allCases)) }
        let alert = ReminderRequest(identifier: "alert.headsup.20261126.SUSPENDED", fireDate: calendar.date(2026, 11, 24, hour: 10), title: "t", body: "b")

        try await scheduler.sync(plans, extra: [alert], now: now, calendar: calendar)
        let pending = await center.pending
        #expect(pending.count == ReminderScheduler.maxPending)
        #expect(pending[alert.identifier] != nil)
    }
}
