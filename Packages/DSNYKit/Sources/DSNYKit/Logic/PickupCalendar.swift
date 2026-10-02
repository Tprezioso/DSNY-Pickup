import Foundation

/// A scheduled collection day. On a holiday or other service change some (or all) streams may be cancelled.
public struct UpcomingPickup: Sendable, Equatable, Identifiable {
    /// Start of the collection day.
    public let date: Date
    /// Streams actually collected that day.
    public let streams: [CollectionStream]
    /// Normally scheduled streams that won't be collected because of `notice`.
    public let cancelled: [CollectionStream]
    /// The service change affecting this day, if any.
    public let notice: ServiceNotice?

    public var id: Date { date }

    public init(date: Date, streams: [CollectionStream], cancelled: [CollectionStream] = [], notice: ServiceNotice? = nil) {
        self.date = date
        self.streams = streams
        self.cancelled = cancelled
        self.notice = notice
    }

    /// "Trash and Recycling".
    public var streamList: String {
        streams.map { String(localized: $0.title) }.formatted(.list(type: .and))
    }

    /// Nothing scheduled that day will be collected.
    public var isFullyCancelled: Bool { streams.isEmpty && !cancelled.isEmpty }
}

/// Date math shared by the app, widget and reminders so they always agree.
public enum PickupCalendar {
    /// Scheduled collection days in the next `days` days, starting with today, with `service` changes applied.
    /// Fully cancelled days are included (with empty `streams`) so callers can mention them.
    public static func scheduledDays(
        _ schedule: CollectionSchedule,
        from now: Date = .now,
        days: Int = 7,
        service: ServiceCalendar = .empty,
        calendar: Calendar = .current
    ) -> [UpcomingPickup] {
        let start = calendar.startOfDay(for: now)
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let scheduled = schedule.streams(on: Weekday(date: date, calendar: calendar))
            guard !scheduled.isEmpty else { return nil }
            guard let notice = service.notice(for: date, calendar: calendar) else {
                return UpcomingPickup(date: date, streams: scheduled)
            }
            let off = notice.status.cancelledStreams
            return UpcomingPickup(
                date: date,
                streams: scheduled.filter { !off.contains($0) },
                cancelled: scheduled.filter(off.contains),
                notice: notice
            )
        }
    }

    /// Days with at least one collection in the next `days` days, starting with today.
    public static func upcoming(
        _ schedule: CollectionSchedule,
        from now: Date = .now,
        days: Int = 7,
        service: ServiceCalendar = .empty,
        calendar: Calendar = .current
    ) -> [UpcomingPickup] {
        scheduledDays(schedule, from: now, days: days, service: service, calendar: calendar).filter { !$0.streams.isEmpty }
    }

    /// The next collection day, including today.
    public static func next(_ schedule: CollectionSchedule, from now: Date = .now, service: ServiceCalendar = .empty, calendar: Calendar = .current) -> UpcomingPickup? {
        // Look a little past a week so a holiday doesn't leave "no pickups".
        upcoming(schedule, from: now, days: 8, service: service, calendar: calendar).first
    }

    /// The first scheduled day in the next week that has a service change, for banners.
    public static func nextChange(_ schedule: CollectionSchedule, from now: Date = .now, service: ServiceCalendar = .empty, calendar: Calendar = .current) -> UpcomingPickup? {
        scheduledDays(schedule, from: now, service: service, calendar: calendar).first { $0.notice != nil }
    }

    /// The next day each stream is collected.
    public static func nextDate(
        for stream: CollectionStream,
        in schedule: CollectionSchedule,
        from now: Date = .now,
        service: ServiceCalendar = .empty,
        calendar: Calendar = .current
    ) -> Date? {
        upcoming(schedule, from: now, days: 14, service: service, calendar: calendar).first { $0.streams.contains(stream) }?.date
    }

    /// "Today", "Tomorrow", or the weekday name for dates later this week.
    public static func relativeDayName(for date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return String(localized: "Today") }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return String(localized: "Tomorrow")
        }
        return Weekday(date: date, calendar: calendar).name
    }

    /// Midnight boundaries for the next `days` days, used for widget timelines.
    public static func midnights(after now: Date, days: Int, calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: now)
        return (1...max(days, 1)).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// Calendar days from `now` to `date`: 0 for today, 1 for tomorrow.
    public static func daysUntil(_ date: Date, from now: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
    }

    /// DSNY's set-out hour: lidded bins may go out from 6 PM the night before collection.
    public static let setOutHour = 18

    /// 6 PM the evening before `pickup`.
    public static func setOutTime(for pickup: UpcomingPickup, calendar: Calendar = .current) -> Date? {
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: pickup.date) else { return nil }
        return calendar.date(bySettingHour: setOutHour, minute: 0, second: 0, of: dayBefore)
    }

    /// What's collected tomorrow, i.e. what goes out tonight.
    /// Includes a fully cancelled day so callers can say "keep your bins in".
    public static func tonight(_ schedule: CollectionSchedule, from now: Date = .now, service: ServiceCalendar = .empty, calendar: Calendar = .current) -> UpcomingPickup? {
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return nil }
        return scheduledDays(schedule, from: tomorrow, days: 1, service: service, calendar: calendar).first
    }

    /// How soon `pickup` is, for countdown displays.
    public static func countdown(to pickup: UpcomingPickup, from now: Date = .now, calendar: Calendar = .current) -> PickupCountdown {
        switch daysUntil(pickup.date, from: now, calendar: calendar) {
        case ...0: .today
        case 1:
            if let setOut = setOutTime(for: pickup, calendar: calendar), now >= setOut { .tonight } else { .tomorrow }
        case let days: .days(days)
        }
    }

    /// When to put `pickup` out, shared by the app, widgets and Siri.
    public static func setOutHint(for pickup: UpcomingPickup, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(pickup.date, inSameDayAs: now) {
            return String(localized: "Collection is today. Bring emptied bins back in after pickup.")
        }
        return String(localized: "Set out after 6 PM the night before in a lidded bin (buildings with 10+ units can put bags out after 8 PM).")
    }
}

/// How far away a pickup is.
public enum PickupCountdown: Sendable, Equatable {
    /// Collection is today.
    case today
    /// Collection is tomorrow and it's already past set-out time.
    case tonight
    /// Collection is tomorrow, before set-out time.
    case tomorrow
    /// Collection is this many days away (2 or more).
    case days(Int)

    /// "Today", "Tonight", "Tmrw", "3d" — short enough for a circular complication.
    public var shortLabel: String {
        switch self {
        case .today: String(localized: "Today")
        case .tonight: String(localized: "Tonight")
        case .tomorrow: String(localized: "Tmrw", comment: "Abbreviation of Tomorrow for a small widget")
        case .days(let days): String(localized: "\(days)d", comment: "Days until pickup, e.g. 3d")
        }
    }

    /// Progress toward pickup over a week, for gauges. 1 is today.
    public var progress: Double {
        switch self {
        case .today: 1
        case .tonight: 0.9
        case .tomorrow: 6.0 / 7.0
        case .days(let days): max(0, Double(7 - days) / 7)
        }
    }
}
