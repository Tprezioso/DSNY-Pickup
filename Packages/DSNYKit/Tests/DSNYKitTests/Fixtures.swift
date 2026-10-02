import Foundation

enum Fixture {
    static func data(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }

    static func string(_ name: String) throws -> String {
        String(decoding: try data(name), as: UTF8.self)
    }
}

extension Calendar {
    /// Gregorian calendar in New York with Sunday as the first weekday, so tests don't depend on the host locale.
    static let newYork: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        calendar.firstWeekday = 1
        return calendar
    }()

    func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
    }
}
