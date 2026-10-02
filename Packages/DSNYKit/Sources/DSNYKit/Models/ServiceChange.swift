import Foundation

/// DSNY's collection status for one day, as published in the NYC 311 city services calendar.
public enum CollectionStatus: Sendable, Equatable, Hashable {
    case onSchedule
    /// No trash, recycling or compost collection (e.g. a holiday).
    case suspended
    /// Collections are running late (e.g. snow).
    case delayed
    case compostSuspended
    case trashAndRecyclingSuspended
    /// Normal non-collection day, such as a Sunday.
    case notInEffect
    case noInformation
    /// A status this version doesn't know. Treated as no change.
    case other(String)

    public init(apiValue: String) {
        switch apiValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "ON SCHEDULE": self = .onSchedule
        case "SUSPENDED": self = .suspended
        case "DELAYED": self = .delayed
        case "COMPOST SUSPENDED": self = .compostSuspended
        case "COLLECTION AND RECYCLING SUSPENDED": self = .trashAndRecyclingSuspended
        case "NOT IN EFFECT": self = .notInEffect
        case "NO INFORMATION": self = .noInformation
        default: self = .other(apiValue)
        }
    }

    /// Streams that won't be collected at all.
    public var cancelledStreams: Set<CollectionStream> {
        switch self {
        case .suspended: Set(CollectionStream.allCases)
        case .compostSuspended: [.compost]
        // Bulk items go out with trash, so they're off too.
        case .trashAndRecyclingSuspended: [.trash, .recycling, .bulk]
        case .onSchedule, .delayed, .notInEffect, .noInformation, .other: []
        }
    }

    /// Whether this status changes what residents should do.
    public var isServiceChange: Bool {
        self == .delayed || !cancelledStreams.isEmpty
    }
}

/// One day of the city services calendar, limited to collections.
public struct ServiceDay: Sendable, Equatable, Codable, Identifiable {
    /// "yyyyMMdd", as in the API. Matched against dates with `ServiceCalendar.dayID(for:calendar:)`.
    public let dayID: String
    public let statusValue: String
    /// e.g. "Trash, recycling, and compost collections are suspended."
    public let details: String?
    /// The holiday or event name, e.g. "Thanksgiving Day".
    public let exceptionName: String?

    public var id: String { dayID }
    public var status: CollectionStatus { CollectionStatus(apiValue: statusValue) }

    public init(dayID: String, statusValue: String, details: String? = nil, exceptionName: String? = nil) {
        self.dayID = dayID
        self.statusValue = statusValue
        self.details = details
        self.exceptionName = exceptionName
    }
}

/// Upcoming collection changes, cached so widgets, Siri and reminders can use them offline.
public struct ServiceCalendar: Sendable, Equatable, Codable {
    public var days: [ServiceDay]
    public var fetchedAt: Date

    public init(days: [ServiceDay], fetchedAt: Date = .now) {
        self.days = days
        self.fetchedAt = fetchedAt
    }

    public static let empty = ServiceCalendar(days: [], fetchedAt: .distantPast)

    public func day(for date: Date, calendar: Calendar = .current) -> ServiceDay? {
        let id = Self.dayID(for: date, calendar: calendar)
        return days.first { $0.dayID == id }
    }

    /// The change on `date`, if collections are affected.
    public func notice(for date: Date, calendar: Calendar = .current) -> ServiceNotice? {
        guard let day = day(for: date, calendar: calendar), day.status.isServiceChange else { return nil }
        return ServiceNotice(day: day)
    }

    static func dayID(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

/// A collection change on a pickup day, worded for people.
public struct ServiceNotice: Sendable, Equatable {
    public let status: CollectionStatus
    public let name: String?
    public let details: String?

    public init(day: ServiceDay) {
        status = day.status
        // The API appends the year ("Thanksgiving Day 2026"), which reads oddly in a sentence.
        name = day.exceptionName?
            .replacing(/\s+\d{4}\s*$/, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
        details = day.details?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    /// "Thanksgiving Day: No Collection", "No Compost Collection", "Collections Delayed".
    public var headline: String {
        let change: String = switch status {
        case .suspended: String(localized: "No Collection")
        case .compostSuspended: String(localized: "No Compost Collection")
        case .trashAndRecyclingSuspended: String(localized: "No Trash or Recycling Collection")
        case .delayed: String(localized: "Collections Delayed")
        default: String(localized: "Service Change")
        }
        guard let name else { return change }
        return "\(name): \(change)"
    }

    public var isDelay: Bool { status == .delayed }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - API response

/// Wire format of `api.nyc.gov/public/api/GetCalendar`.
struct ServiceCalendarResponse: Decodable {
    struct Day: Decodable {
        let todayID: String
        let items: [Item]

        enum CodingKeys: String, CodingKey {
            case todayID = "today_id"
            case items
        }
    }

    struct Item: Decodable {
        let type: String
        let status: String
        let details: String?
        let exceptionName: String?
    }

    let days: [Day]

    /// The collections entry for each day; other services (parking, schools) are dropped.
    func serviceDays() -> [ServiceDay] {
        days.compactMap { day in
            guard let item = day.items.first(where: { $0.type.caseInsensitiveCompare("Collections") == .orderedSame }) else { return nil }
            return ServiceDay(dayID: day.todayID, statusValue: item.status, details: item.details, exceptionName: item.exceptionName)
        }
    }
}
