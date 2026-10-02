import Foundation
import UserNotifications

/// Everything needed to schedule reminders for one address. A value snapshot of `SavedAddress`.
public struct ReminderPlan: Sendable, Equatable {
    public var addressID: UUID
    public var addressName: String
    public var schedule: CollectionSchedule
    public var isEnabled: Bool
    public var minutesAfterMidnight: Int
    public var timing: ReminderTiming
    public var streams: Set<CollectionStream>

    public init(
        addressID: UUID,
        addressName: String,
        schedule: CollectionSchedule,
        isEnabled: Bool,
        minutesAfterMidnight: Int,
        timing: ReminderTiming,
        streams: Set<CollectionStream>
    ) {
        self.addressID = addressID
        self.addressName = addressName
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.minutesAfterMidnight = minutesAfterMidnight
        self.timing = timing
        self.streams = streams
    }
}

/// A one-shot notification at a specific local time, independent of `UserNotifications` so it can be unit tested.
public struct ReminderRequest: Sendable, Equatable {
    public let identifier: String
    /// When it fires, in the device's calendar.
    public let fireDate: Date
    public let title: String
    public let body: String

    public init(identifier: String, fireDate: Date, title: String, body: String) {
        self.identifier = identifier
        self.fireDate = fireDate
        self.title = title
        self.body = body
    }
}

/// The parts of `UNUserNotificationCenter` the scheduler uses, so tests can substitute a fake.
public protocol NotificationCenterClient: Sendable {
    func pendingIdentifiers() async -> [String]
    func add(_ request: ReminderRequest) async throws
    func removePending(identifiers: [String]) async
    func requestAuthorization() async throws -> Bool
}

/// Keeps pending notifications in sync with saved addresses and DSNY service changes.
///
/// Reminders are dated, one-shot notifications for the next `windowDays` days rather than weekly
/// repeats, so a holiday can change or cancel a single week's reminder. The window is refilled on
/// every launch, save and background refresh. Identifiers are deterministic
/// (`reminder.<address id>.<yyyyMMdd>`), so rescheduling replaces rather than duplicates.
public actor ReminderScheduler {
    static let prefix = "reminder."
    /// How far ahead reminders are scheduled.
    public static let windowDays = 21
    /// iOS keeps at most 64 pending notifications per app; leave a little headroom.
    public static let maxPending = 60
    /// Most service alerts kept pending at once.
    public static let maxAlerts = 10

    private let center: any NotificationCenterClient

    public init(center: any NotificationCenterClient = SystemNotificationCenter()) {
        self.center = center
    }

    /// Asks for notification permission. Call when the user first turns reminders on.
    public func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization()) ?? false
    }

    /// Replaces every notification the app owns with reminders for `plans` plus `extra`
    /// (e.g. service alerts), soonest first, up to `maxPending`. Also removes weekly repeating
    /// reminders left by older app versions.
    public func sync(
        _ plans: [ReminderPlan],
        service: ServiceCalendar = .empty,
        extra: [ReminderRequest] = [],
        now: Date = .now,
        calendar: Calendar = .current
    ) async throws {
        // Alerts are rare and time-sensitive, so they get first claim on the budget.
        let alerts = extra.filter { $0.fireDate > now }.sorted { $0.fireDate < $1.fireDate }.prefix(Self.maxAlerts)
        let reminders = plans.flatMap { Self.requests(for: $0, from: now, service: service, calendar: calendar) }
            .filter { $0.fireDate > now }
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(Self.maxPending - alerts.count)

        let pending = await center.pendingIdentifiers()
        await center.removePending(identifiers: pending)
        for request in Array(alerts) + Array(reminders) {
            try await center.add(request)
        }
    }

    /// Delivers a one-off notification (e.g. a breaking service alert) without touching scheduled ones.
    public func post(_ request: ReminderRequest) async throws {
        try await center.add(request)
    }

    /// Reminders for one address over the next `windowDays`: one per pickup day, listing every enabled
    /// stream that's actually collected, or a "keep your bins in" note when the day is cancelled.
    public static func requests(
        for plan: ReminderPlan,
        from now: Date = .now,
        service: ServiceCalendar = .empty,
        calendar: Calendar = .current
    ) -> [ReminderRequest] {
        guard plan.isEnabled, !plan.streams.isEmpty else { return [] }
        let hour = min(max(plan.minutesAfterMidnight / 60, 0), 23)
        let minute = min(max(plan.minutesAfterMidnight % 60, 0), 59)

        let days = PickupCalendar.scheduledDays(plan.schedule, from: now, days: windowDays + 1, service: service, calendar: calendar)
        return days.compactMap { pickup in
            let collected = pickup.streams.filter(plan.streams.contains)
            let cancelled = pickup.cancelled.filter(plan.streams.contains)
            guard !collected.isEmpty || !cancelled.isEmpty else { return nil }

            let fireDay = plan.timing == .dayBefore ? calendar.date(byAdding: .day, value: -1, to: pickup.date) : pickup.date
            guard let fireDay, let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: fireDay) else { return nil }

            let (title, body) = content(collected: collected, notice: pickup.notice, timing: plan.timing, addressName: plan.addressName)
            return ReminderRequest(
                identifier: "\(prefix)\(plan.addressID.uuidString).\(ServiceCalendar.dayID(for: pickup.date, calendar: calendar))",
                fireDate: fireDate,
                title: title,
                body: body
            )
        }
    }

    static func content(collected: [CollectionStream], notice: ServiceNotice?, timing: ReminderTiming, addressName: String) -> (title: String, body: String) {
        let list = collected.map { String(localized: $0.title) }.formatted(.list(type: .and))

        guard !collected.isEmpty else {
            let title = timing == .dayBefore ? String(localized: "No collection tomorrow") : String(localized: "No collection today")
            let reason = notice?.name.map { "\($0). " } ?? ""
            return (title, String(localized: "\(reason)Keep your bins in at \(addressName)."))
        }

        let title = timing == .dayBefore ? String(localized: "Tomorrow: \(list)") : String(localized: "Today: \(list)")
        var body = String(localized: "Set out your bins at \(addressName).")
        if let notice {
            body = "\(notice.headline). " + body
        }
        return (title, body)
    }
}

/// `UNUserNotificationCenter` adapter.
public struct SystemNotificationCenter: NotificationCenterClient {
    public init() {}

    public func pendingIdentifiers() async -> [String] {
        await UNUserNotificationCenter.current().pendingNotificationRequests().map(\.identifier)
    }

    public func add(_ request: ReminderRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        content.threadIdentifier = request.identifier.hasPrefix(ServiceAlertPlanner.prefix) ? "service-alerts" : "pickup-reminders"
        if request.identifier.hasPrefix(ServiceAlertPlanner.prefix) {
            content.interruptionLevel = .timeSensitive
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: request.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        try await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger)
        )
    }

    public func removePending(identifiers: [String]) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }
}
