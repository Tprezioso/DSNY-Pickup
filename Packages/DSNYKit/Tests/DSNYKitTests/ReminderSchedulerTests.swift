import Foundation
import Testing
@testable import DSNYKit

/// Records calls instead of touching `UNUserNotificationCenter`.
actor FakeNotificationCenter: NotificationCenterClient {
    var pending: [String: ReminderRequest] = [:]
    var legacy: Set<String> = []

    init(legacy: Set<String> = []) {
        self.legacy = legacy
    }

    func pendingIdentifiers() async -> [String] { Array(pending.keys) + legacy }
    func add(_ request: ReminderRequest) async throws { pending[request.identifier] = request }
    func removePending(identifiers: [String]) async {
        identifiers.forEach { pending[$0] = nil; legacy.remove($0) }
    }
    func requestAuthorization() async throws -> Bool { true }
}

@Suite("Reminders")
struct ReminderSchedulerTests {
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    let calendar = Calendar.newYork
    /// Monday Nov 2, 2026, noon.
    var monday: Date { calendar.date(2026, 11, 2) }

    func plan(timing: ReminderTiming = .dayBefore, streams: Set<CollectionStream> = Set(CollectionStream.allCases), enabled: Bool = true) -> ReminderPlan {
        ReminderPlan(addressID: id, addressName: "Home", schedule: .sample, isEnabled: enabled, minutesAfterMidnight: 20 * 60 + 30, timing: timing, streams: streams)
    }

    func requests(_ plan: ReminderPlan, service: ServiceCalendar = .empty) -> [ReminderRequest] {
        ReminderScheduler.requests(for: plan, from: monday, service: service, calendar: calendar)
    }

    @Test("One dated reminder per pickup day across the window, combining streams")
    func combinesStreams() throws {
        let all = requests(plan())
        // Tue/Thu/Sat for three weeks (Nov 3 – Nov 21).
        #expect(all.count == 9)
        let saturday = try #require(all.first { $0.identifier.hasSuffix(".20261107") })
        #expect(saturday.title == "Tomorrow: Trash, Recycling, and Compost")
        #expect(saturday.body.contains("Home"))
        #expect(saturday.fireDate == calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 20, minute: 30)))
    }

    @Test("Night-before reminders fire the previous day, morning-of on the day")
    func timing() {
        let nightBefore = requests(plan()).prefix(3).map { Weekday(date: $0.fireDate, calendar: calendar) }
        #expect(nightBefore == [.monday, .wednesday, .friday])

        let morningOf = requests(plan(timing: .dayOf))
        #expect(morningOf.prefix(3).map { Weekday(date: $0.fireDate, calendar: calendar) } == [.tuesday, .thursday, .saturday])
        #expect(morningOf.allSatisfy { $0.title.hasPrefix("Today:") })
    }

    @Test("Sunday pickups remind on Saturday")
    func sundayWraps() {
        var sundayPlan = plan()
        sundayPlan.schedule = CollectionSchedule(formattedAddress: "x", rawSchedules: [.trash: "Sunday"])
        #expect(requests(sundayPlan).map { Weekday(date: $0.fireDate, calendar: calendar) }.allSatisfy { $0 == .saturday })
    }

    @Test("Only selected streams are included")
    func filtersStreams() {
        let all = requests(plan(streams: [.recycling]))
        #expect(all.count == 3)
        #expect(all.first?.title == "Tomorrow: Recycling")
    }

    @Test("Disabled plans schedule nothing")
    func disabled() {
        #expect(requests(plan(enabled: false)).isEmpty)
    }

    @Test("A suspended day says to keep bins in; a partial day lists what's left")
    func holidays() throws {
        let service = ServiceCalendar(days: [
            ServiceDay(dayID: "20261105", statusValue: "SUSPENDED", exceptionName: "Election Day"),
            ServiceDay(dayID: "20261107", statusValue: "COMPOST SUSPENDED")
        ])
        let all = requests(plan(), service: service)

        let thursday = try #require(all.first { $0.identifier.hasSuffix(".20261105") })
        #expect(thursday.title == "No collection tomorrow")
        #expect(thursday.body == "Election Day. Keep your bins in at Home.")

        let saturday = try #require(all.first { $0.identifier.hasSuffix(".20261107") })
        #expect(saturday.title == "Tomorrow: Trash and Recycling")
        #expect(saturday.body.hasPrefix("No Compost Collection."))

        // Someone who only wants compost reminders hears that Saturday's compost is off.
        let compostOnly = requests(plan(streams: [.compost]), service: service)
        #expect(compostOnly.first { $0.identifier.hasSuffix(".20261107") }?.title == "No collection tomorrow")
    }

    @Test("Sync replaces old and legacy reminders, drops past ones, and caps the total")
    func sync() async throws {
        let center = FakeNotificationCenter(legacy: ["reminder.\(id.uuidString).7", "9F2C-random-legacy-id"])
        let scheduler = ReminderScheduler(center: center)

        try await scheduler.sync([plan()], now: monday, calendar: calendar)
        try await scheduler.sync([plan(streams: [.recycling])], now: monday, calendar: calendar)
        #expect(Set(await center.pendingIdentifiers()) == ["reminder.\(id.uuidString).20261107", "reminder.\(id.uuidString).20261114", "reminder.\(id.uuidString).20261121"])

        // Many addresses can't exceed the iOS limit; the soonest are kept.
        let plans = (0..<10).map { _ in ReminderPlan(addressID: UUID(), addressName: "x", schedule: .sample, isEnabled: true, minutesAfterMidnight: 19 * 60, timing: .dayBefore, streams: Set(CollectionStream.allCases)) }
        try await scheduler.sync(plans, now: monday, calendar: calendar)
        let pending = await center.pending.values
        #expect(pending.count == ReminderScheduler.maxPending)
        #expect(pending.allSatisfy { $0.fireDate > monday })
    }
}
