import Foundation

/// Decides which service change alerts (a Pro feature) to send. Pure, so it's unit tested;
/// `ReminderScheduler` delivers the results.
public enum ServiceAlertPlanner {
    static let prefix = "alert."
    /// Heads-ups go out at 10 AM, two days before the change.
    static let headsUpHour = 10
    static let headsUpLeadDays = 2
    /// How soon a newly published change has to be to deserve an immediate alert.
    static let breakingWindowDays = 2

    /// Scheduled heads-ups for changes in `service` that land on one of the addresses' pickup days.
    /// One alert per changed day, covering every affected address.
    public static func headsUps(
        for addresses: [AddressSnapshot],
        service: ServiceCalendar,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ReminderRequest] {
        affectedDays(addresses: addresses, service: service, from: now, days: 14, calendar: calendar).compactMap { day in
            guard let fireDay = calendar.date(byAdding: .day, value: -headsUpLeadDays, to: day.date),
                  let fireDate = calendar.date(bySettingHour: headsUpHour, minute: 0, second: 0, of: fireDay),
                  fireDate > now else { return nil }
            return request(for: day, kind: "headsup", fireDate: fireDate, now: now, calendar: calendar)
        }
    }

    /// Changes in `new` that weren't in `old` (e.g. a snow delay announced this morning) and affect a pickup
    /// in the next two days. Fires right away. Returns nothing on the first download, so installing the
    /// app doesn't trigger a burst of alerts.
    public static func breakingAlerts(
        old: ServiceCalendar,
        new: ServiceCalendar,
        for addresses: [AddressSnapshot],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ReminderRequest] {
        guard old.fetchedAt != .distantPast else { return [] }
        let known = Set(old.days.filter { $0.status.isServiceChange }.map { "\($0.dayID)|\($0.statusValue)" })
        return affectedDays(addresses: addresses, service: new, from: now, days: breakingWindowDays + 1, calendar: calendar)
            .filter { !known.contains("\($0.dayID)|\($0.statusValue)") }
            .map { request(for: $0, kind: "now", fireDate: now.addingTimeInterval(2), now: now, calendar: calendar) }
    }

    // MARK: - Helpers

    struct AffectedDay {
        let date: Date
        let dayID: String
        let statusValue: String
        let notice: ServiceNotice
        /// Address name → its scheduled pickup that day.
        let pickups: [(name: String, pickup: UpcomingPickup)]
    }

    static func affectedDays(addresses: [AddressSnapshot], service: ServiceCalendar, from now: Date, days: Int, calendar: Calendar) -> [AffectedDay] {
        var byDay: [String: AffectedDay] = [:]
        for address in addresses {
            let changed = PickupCalendar.scheduledDays(address.schedule, from: now, days: days, service: service, calendar: calendar)
                .filter { $0.notice != nil && (!$0.cancelled.isEmpty || $0.notice?.isDelay == true) }
            for pickup in changed {
                guard let notice = pickup.notice, let day = service.day(for: pickup.date, calendar: calendar) else { continue }
                let existing = byDay[day.dayID]
                byDay[day.dayID] = AffectedDay(
                    date: pickup.date,
                    dayID: day.dayID,
                    statusValue: day.statusValue,
                    notice: notice,
                    pickups: (existing?.pickups ?? []) + [(address.name, pickup)]
                )
            }
        }
        return byDay.values.sorted { $0.date < $1.date }
    }

    static func request(for day: AffectedDay, kind: String, fireDate: Date, now: Date, calendar: Calendar) -> ReminderRequest {
        let when = PickupCalendar.relativeDayName(for: day.date, now: fireDate, calendar: calendar)
        let lines = day.pickups.map { name, pickup -> String in
            if day.notice.isDelay {
                return String(localized: "Collections at \(name) may run late. Leave your bins out until they're picked up.")
            }
            let off = pickup.cancelled.map { String(localized: $0.title) }.formatted(.list(type: .and))
            return pickup.isFullyCancelled
                ? String(localized: "No \(off) at \(name). Keep your bins in.")
                : String(localized: "No \(off) at \(name). \(pickup.streamList) still goes out.")
        }
        return ReminderRequest(
            identifier: "\(prefix)\(kind).\(day.dayID).\(day.statusValue)",
            fireDate: fireDate,
            title: "\(when): \(day.notice.headline)",
            body: lines.joined(separator: "\n")
        )
    }
}
