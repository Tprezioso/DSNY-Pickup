import Foundation
import SwiftData

/// When a pickup reminder fires relative to the collection day.
public enum ReminderTiming: String, CaseIterable, Codable, Sendable, Identifiable {
    case dayBefore
    case dayOf

    public var id: String { rawValue }

    public var title: LocalizedStringResource {
        switch self {
        case .dayBefore: "Night Before"
        case .dayOf: "Morning Of"
        }
    }

    /// Suggested reminder time in minutes after midnight. DSNY allows set-out from 6 PM the night before
    /// (lidded bins), so night-before reminders default to 7 PM.
    public var defaultMinutes: Int {
        switch self {
        case .dayBefore: 19 * 60
        case .dayOf: 6 * 60
        }
    }
}

/// An address the user saved, with its last known schedule and reminder settings.
/// Stored in the app group so the widget can read it.
@Model
public final class SavedAddress {
    public var id: UUID = UUID()
    /// Optional nickname such as "Home". Empty when unset.
    public var label: String = ""
    /// Address as DSNY formats it, e.g. "125 Worth St, New York, NY 10013, USA".
    public var formattedAddress: String = ""
    /// The address string that was sent to DSNY; reused for refreshes.
    public var queryAddress: String = ""
    public var createdAt: Date = Date.now
    public var lastRefreshed: Date = Date.now
    /// Display and "primary address" order; lowest first.
    public var sortOrder: Int = 0

    public var trashSchedule: String = ""
    public var recyclingSchedule: String = ""
    public var compostSchedule: String = ""
    public var bulkSchedule: String = ""
    public var residentialRoutingTime: String?
    public var commercialRoutingTime: String?
    public var mixedUseRoutingTime: String?

    public var remindersEnabled: Bool = false
    /// Reminder time in minutes after midnight.
    public var reminderMinutes: Int = 19 * 60
    public var reminderTimingRaw: String = ReminderTiming.dayBefore.rawValue
    public var reminderStreamsRaw: [String] = CollectionStream.allCases.map(\.rawValue)

    public init(schedule: CollectionSchedule, queryAddress: String, label: String = "", sortOrder: Int = 0) {
        self.queryAddress = queryAddress
        self.label = label
        self.sortOrder = sortOrder
        self.schedule = schedule
    }

    // MARK: Derived values

    /// The schedule as a value type. Setting it also stamps `lastRefreshed`.
    public var schedule: CollectionSchedule {
        get {
            CollectionSchedule(
                formattedAddress: formattedAddress,
                rawSchedules: [.trash: trashSchedule, .recycling: recyclingSchedule, .compost: compostSchedule, .bulk: bulkSchedule],
                residentialRoutingTime: residentialRoutingTime,
                commercialRoutingTime: commercialRoutingTime,
                mixedUseRoutingTime: mixedUseRoutingTime
            )
        }
        set {
            formattedAddress = newValue.formattedAddress
            trashSchedule = newValue.rawSchedules[.trash] ?? ""
            recyclingSchedule = newValue.rawSchedules[.recycling] ?? ""
            compostSchedule = newValue.rawSchedules[.compost] ?? ""
            bulkSchedule = newValue.rawSchedules[.bulk] ?? ""
            residentialRoutingTime = newValue.residentialRoutingTime
            commercialRoutingTime = newValue.commercialRoutingTime
            mixedUseRoutingTime = newValue.mixedUseRoutingTime
            lastRefreshed = .now
        }
    }

    /// The nickname, or the street part of the address.
    public var displayName: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? shortAddress : trimmed
    }

    /// "125 Worth St" from "125 Worth St, New York, NY 10013, USA".
    public var shortAddress: String {
        formattedAddress.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? formattedAddress
    }

    public var reminderTiming: ReminderTiming {
        get { ReminderTiming(rawValue: reminderTimingRaw) ?? .dayBefore }
        set { reminderTimingRaw = newValue.rawValue }
    }

    public var reminderStreams: Set<CollectionStream> {
        get { Set(reminderStreamsRaw.compactMap(CollectionStream.init(rawValue:))) }
        set { reminderStreamsRaw = CollectionStream.allCases.filter(newValue.contains).map(\.rawValue) }
    }

    /// A Sendable snapshot for scheduling notifications off the main actor.
    public var reminderPlan: ReminderPlan {
        ReminderPlan(
            addressID: id,
            addressName: displayName,
            schedule: schedule,
            isEnabled: remindersEnabled,
            minutesAfterMidnight: reminderMinutes,
            timing: reminderTiming,
            streams: reminderStreams
        )
    }

    /// Whether the cached schedule is old enough to refresh in the background.
    public func needsRefresh(now: Date = .now) -> Bool {
        now.timeIntervalSince(lastRefreshed) > 60 * 60 * 24
    }
}
