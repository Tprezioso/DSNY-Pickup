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

    func plan(timing: ReminderTiming = .dayBefore, streams: Set<CollectionStream> = Set(CollectionStream.allCases), enabled: Bool = true) -> ReminderPlan {
        ReminderPlan(addressID: id, addressName: "Home", schedule: .sample, isEnabled: enabled, minutesAfterMidnight: 20 * 60 + 30, timing: timing, streams: streams)
    }

    @Test("One reminder per pickup day, combining streams")
    func combinesStreams() {
        let requests = ReminderScheduler.requests(for: plan())
        #expect(requests.count == 3) // Tue, Thu, Sat
        let saturday = requests.first { $0.identifier.hasSuffix(".\(Weekday.saturday.rawValue)") }
        #expect(saturday?.title == "Tomorrow: Trash, Recycling, and Compost")
        #expect(saturday?.body.contains("Home") == true)
        #expect(saturday?.hour == 20)
        #expect(saturday?.minute == 30)
    }

    @Test("Night-before reminders fire the previous weekday")
    func dayBeforeShift() {
        let requests = ReminderScheduler.requests(for: plan())
        #expect(Set(requests.map(\.weekday)) == [.monday, .wednesday, .friday])
    }

    @Test("Sunday pickups remind on Saturday")
    func sundayWraps() {
        var sundayPlan = plan()
        sundayPlan.schedule = CollectionSchedule(formattedAddress: "x", rawSchedules: [.trash: "Sunday"])
        #expect(ReminderScheduler.requests(for: sundayPlan).map(\.weekday) == [.saturday])
    }

    @Test("Morning-of reminders fire on the pickup day")
    func dayOf() {
        let requests = ReminderScheduler.requests(for: plan(timing: .dayOf))
        #expect(Set(requests.map(\.weekday)) == [.tuesday, .thursday, .saturday])
        #expect(requests.allSatisfy { $0.title.hasPrefix("Today:") })
    }

    @Test("Only selected streams are included")
    func filtersStreams() {
        let requests = ReminderScheduler.requests(for: plan(streams: [.recycling]))
        #expect(requests.count == 1)
        #expect(requests.first?.title == "Tomorrow: Recycling")
    }

    @Test("Disabled plans schedule nothing")
    func disabled() {
        #expect(ReminderScheduler.requests(for: plan(enabled: false)).isEmpty)
    }

    @Test("Sync replaces old and legacy reminders")
    func sync() async throws {
        let center = FakeNotificationCenter(legacy: ["9F2C-random-legacy-id"])
        let scheduler = ReminderScheduler(center: center)

        try await scheduler.sync([plan()])
        try await scheduler.sync([plan(streams: [.recycling])])

        let pending = await center.pendingIdentifiers()
        #expect(pending == ["reminder.\(id.uuidString).7"])
    }
}
