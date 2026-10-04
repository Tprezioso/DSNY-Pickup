import Foundation

/// A day of the week whose raw value matches `Calendar`'s weekday numbering (Sunday = 1).
public enum Weekday: Int, CaseIterable, Codable, Sendable, Comparable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    public var id: Int { rawValue }

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }

    /// The weekday of `date` in `calendar`.
    public init(date: Date, calendar: Calendar = .current) {
        // `Calendar.component(.weekday:)` is always 1...7.
        self = Weekday(rawValue: calendar.component(.weekday, from: date)) ?? .sunday
    }

    /// Parses a day name such as "Monday", "MON" or " tuesday ". Returns `nil` for anything else.
    public init?(name: String) {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard key.count >= 3 else { return nil }
        guard let match = Weekday.allCases.first(where: { $0.englishName.lowercased().hasPrefix(key) || key.hasPrefix($0.englishName.lowercased()) }) else {
            return nil
        }
        self = match
    }

    /// Parses a comma separated list as returned by the DSNY schedule API, e.g. "Tuesday,Thursday,Saturday".
    public static func parseList(_ text: String?) -> Set<Weekday> {
        guard let text else { return [] }
        return Set(text.split(whereSeparator: { $0 == "," || $0 == "/" || $0 == "&" }).compactMap { Weekday(name: String($0)) })
    }

    /// The day before, wrapping Sunday to Saturday.
    public var previous: Weekday { Weekday(rawValue: rawValue == 1 ? 7 : rawValue - 1) ?? .saturday }

    /// The day after, wrapping Saturday to Sunday.
    public var next: Weekday { Weekday(rawValue: rawValue == 7 ? 1 : rawValue + 1) ?? .sunday }

    /// Stable English name used for parsing API values.
    var englishName: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }

    /// Localized full name, e.g. "Monday".
    public var name: String { Calendar.current.weekdaySymbols[rawValue - 1] }

    /// Localized short name, e.g. "Mon".
    public var shortName: String { Calendar.current.shortWeekdaySymbols[rawValue - 1] }

    /// Localized single letter, e.g. "M".
    public var initial: String { Calendar.current.veryShortWeekdaySymbols[rawValue - 1] }

    /// Days ordered starting from the user's first weekday.
    public static func ordered(calendar: Calendar = .current) -> [Weekday] {
        let first = calendar.firstWeekday
        return (0..<7).compactMap { Weekday(rawValue: (first - 1 + $0) % 7 + 1) }
    }
}

public extension Set<Weekday> {
    /// Sorted, localized short names joined with commas, e.g. "Tue, Thu, Sat".
    var shortList: String {
        Weekday.ordered().filter(contains).map(\.shortName).joined(separator: ", ")
    }
}
