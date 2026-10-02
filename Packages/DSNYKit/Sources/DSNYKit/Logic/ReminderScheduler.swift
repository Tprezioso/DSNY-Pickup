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

/// A weekly repeating reminder, independent of `UserNotifications` so it can be unit tested.
public struct ReminderRequest: Sendable, Equatable {
    public let identifier: String
    /// Weekday the notification fires (the day before pickup for night-before reminders).
    public let weekday: Weekday
    public let hour: Int
    public let minute: Int
    public let title: String
    public let body: String
}

/// The parts of `UNUserNotificationCenter` the scheduler uses, so tests can substitute a fake.
public protocol NotificationCenterClient: Sendable {
    func pendingIdentifiers() async -> [String]
    func add(_ request: ReminderRequest) async throws
    func removePending(identifiers: [String]) async
    func requestAuthorization() async throws -> Bool
}

/// Keeps pending notifications in sync with saved addresses.
///
/// Identifiers are deterministic (`reminder.<address id>.<pickup weekday>`), so rescheduling
/// always replaces the old requests instead of piling up duplicates.
public actor ReminderScheduler {
    static let prefix = "reminder."

    private let center: any NotificationCenterClient

    public init(center: any NotificationCenterClient = SystemNotificationCenter()) {
        self.center = center
    }

    /// Asks for notification permission. Call when the user first turns reminders on.
    public func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization()) ?? false
    }

    /// Replaces every reminder the app owns with the ones described by `plans`.
    /// Also removes reminders left behind by older app versions, which used random identifiers.
    public func sync(_ plans: [ReminderPlan]) async throws {
        let pending = await center.pendingIdentifiers()
        await center.removePending(identifiers: pending)
        for plan in plans {
            for request in Self.requests(for: plan) {
                try await center.add(request)
            }
        }
    }

    /// Builds the requests for one address: one per pickup day, listing every enabled stream that day.
    public static func requests(for plan: ReminderPlan) -> [ReminderRequest] {
        guard plan.isEnabled, !plan.streams.isEmpty else { return [] }
        let hour = min(max(plan.minutesAfterMidnight / 60, 0), 23)
        let minute = min(max(plan.minutesAfterMidnight % 60, 0), 59)

        return Weekday.allCases.compactMap { pickupDay in
            let streams = plan.schedule.streams(on: pickupDay).filter(plan.streams.contains)
            guard !streams.isEmpty else { return nil }
            let list = streams.map { String(localized: $0.title) }.formatted(.list(type: .and))

            let title: String
            let fireDay: Weekday
            switch plan.timing {
            case .dayBefore:
                fireDay = pickupDay.previous
                title = String(localized: "Tomorrow: \(list)")
            case .dayOf:
                fireDay = pickupDay
                title = String(localized: "Today: \(list)")
            }

            return ReminderRequest(
                identifier: "\(prefix)\(plan.addressID.uuidString).\(pickupDay.rawValue)",
                weekday: fireDay,
                hour: hour,
                minute: minute,
                title: title,
                body: String(localized: "Set out your bins at \(plan.addressName).")
            )
        }
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
        content.threadIdentifier = "pickup-reminders"

        var components = DateComponents()
        components.weekday = request.weekday.rawValue
        components.hour = request.hour
        components.minute = request.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

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
