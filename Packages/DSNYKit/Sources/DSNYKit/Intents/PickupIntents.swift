import AppIntents
import Foundation
import SwiftUI

/// Registers this package's intents and entities with the app and widget targets that link it.
public struct DSNYKitIntentsPackage: AppIntentsPackage {}

enum PickupIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noAddresses

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noAddresses: "You haven't saved an address yet. Open DSNY Pickup and add one first."
        }
    }
}

extension AddressSnapshot {
    /// The chosen address, or the primary one.
    static func resolve(_ entity: AddressEntity?) throws -> AddressSnapshot {
        guard let snapshot = find(entity?.id) else { throw PickupIntentError.noAddresses }
        return snapshot
    }
}

extension PickupCalendar {
    /// "today", "tomorrow" or "on Thursday", for use mid-sentence.
    static func spokenDay(for date: Date, now: Date, calendar: Calendar = .current) -> String {
        switch daysUntil(date, from: now, calendar: calendar) {
        case ...0: String(localized: "today")
        case 1: String(localized: "tomorrow")
        default: String(localized: "on \(Weekday(date: date, calendar: calendar).name)")
        }
    }
}

// MARK: - Next pickup

/// "When is my next pickup?"
public struct NextPickupIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Next Pickup"
    public static let description = IntentDescription(
        "Tells you what's collected next at a saved address and when to set it out.",
        categoryName: "Pickups",
        searchKeywords: ["trash", "garbage", "recycling", "compost", "collection"]
    )

    @Parameter(title: "Address", description: "Leave empty to use your first saved address.")
    public var address: AddressEntity?

    public static var parameterSummary: some ParameterSummary {
        Summary("Get the next pickup at \(\.$address)")
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<AddressEntity> & ProvidesDialog & ShowsSnippetView {
        let snapshot = try AddressSnapshot.resolve(address)
        let now = Date.now
        let next = snapshot.next(from: now)
        // A cancelled day before the next pickup is worth mentioning ("No collection Thursday for Thanksgiving").
        let skipped = snapshot.nextChange(from: now).flatMap { change in
            change.isFullyCancelled && (next.map { change.date < $0.date } ?? true) ? change : nil
        }

        var sentences: [String] = []
        if let skipped, let notice = skipped.notice {
            let day = PickupCalendar.spokenDay(for: skipped.date, now: now)
            sentences.append(String(localized: "There's no collection \(day) (\(notice.name ?? notice.headline))."))
        }
        if let next {
            let day = PickupCalendar.spokenDay(for: next.date, now: now)
            sentences.append(String(localized: "\(next.streamList) \(day) at \(snapshot.name)."))
            if let notice = next.notice { sentences.append("\(notice.headline).") }
            sentences.append(PickupCalendar.setOutHint(for: next, now: now))
        } else {
            sentences.append(String(localized: "There are no pickups scheduled at \(snapshot.name) this week."))
        }

        return .result(
            value: snapshot.entity(now: now),
            dialog: IntentDialog(stringLiteral: sentences.joined(separator: " ")),
            view: PickupSnippetView(
                addressName: snapshot.name,
                headline: next.map { PickupCalendar.relativeDayName(for: $0.date, now: now) } ?? String(localized: "No pickups this week"),
                streams: next?.streams ?? [],
                hint: next.map { PickupCalendar.setOutHint(for: $0, now: now) },
                notice: (skipped ?? next)?.notice?.headline,
                schedule: snapshot.schedule,
                now: now
            )
        )
    }
}

// MARK: - A specific stream

/// "When is recycling?"
public struct StreamPickupIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Pickup Day"
    public static let description = IntentDescription(
        "Tells you when trash, recycling, compost or bulk items are collected next.",
        categoryName: "Pickups"
    )

    @Parameter(title: "Collection", default: .recycling)
    public var stream: CollectionStream

    @Parameter(title: "Address", description: "Leave empty to use your first saved address.")
    public var address: AddressEntity?

    public static var parameterSummary: some ParameterSummary {
        Summary("When is \(\.$stream) at \(\.$address)")
    }

    public init() {}

    public init(stream: CollectionStream, address: AddressEntity? = nil) {
        self.stream = stream
        self.address = address
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let snapshot = try AddressSnapshot.resolve(address)
        let now = Date.now
        let title = String(localized: stream.title)
        let days = snapshot.schedule.days(for: stream)
        let nextDate = PickupCalendar.nextDate(for: stream, in: snapshot.schedule, from: now, service: snapshot.service)

        let dialog: IntentDialog
        let headline: String
        if let nextDate {
            let day = PickupCalendar.spokenDay(for: nextDate, now: now)
            dialog = "\(title) at \(snapshot.name) is collected \(day). It's picked up every \(days.shortList)."
            headline = PickupCalendar.relativeDayName(for: nextDate, now: now)
        } else if let text = snapshot.schedule.unparsedText(for: stream) {
            dialog = "For \(title) at \(snapshot.name), DSNY says: \(text)."
            headline = text
        } else {
            dialog = "\(title) isn't collected at \(snapshot.name)."
            headline = String(localized: "Not collected")
        }

        return .result(
            dialog: dialog,
            view: PickupSnippetView(
                addressName: snapshot.name,
                headline: headline,
                streams: nextDate == nil ? [] : [stream],
                hint: nil,
                schedule: snapshot.schedule,
                now: now
            )
        )
    }
}

// MARK: - Tonight

/// "What goes out tonight?"
public struct TonightIntent: AppIntent {
    public static let title: LocalizedStringResource = "What Goes Out Tonight"
    public static let description = IntentDescription(
        "Tells you which bins to put out tonight for tomorrow's collection.",
        categoryName: "Pickups"
    )

    @Parameter(title: "Address", description: "Leave empty to use your first saved address.")
    public var address: AddressEntity?

    public static var parameterSummary: some ParameterSummary {
        Summary("What goes out tonight at \(\.$address)")
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let snapshot = try AddressSnapshot.resolve(address)
        let now = Date.now
        let tonight = PickupCalendar.tonight(snapshot.schedule, from: now, service: snapshot.service)
        let next = snapshot.next(from: now)

        let dialog: IntentDialog
        let headline: String
        if let tonight, tonight.isFullyCancelled {
            let reason = tonight.notice?.name ?? tonight.notice?.headline ?? ""
            dialog = "Keep your bins in tonight at \(snapshot.name). There's no collection tomorrow (\(reason))."
            headline = String(localized: "Nothing tonight")
        } else if let tonight {
            let change = tonight.notice.map { " \($0.headline)." } ?? ""
            dialog = "Put out \(tonight.streamList) at \(snapshot.name) tonight after 6 PM.\(change)"
            headline = String(localized: "Tonight")
        } else if let next {
            let day = PickupCalendar.spokenDay(for: next.date, now: now)
            dialog = "Nothing goes out tonight at \(snapshot.name). Next up is \(next.streamList) \(day)."
            headline = String(localized: "Nothing tonight")
        } else {
            dialog = "Nothing goes out tonight at \(snapshot.name)."
            headline = String(localized: "Nothing tonight")
        }

        return .result(
            dialog: dialog,
            view: PickupSnippetView(
                addressName: snapshot.name,
                headline: headline,
                streams: tonight?.streams ?? [],
                hint: tonight.flatMap { $0.streams.isEmpty ? nil : PickupCalendar.setOutHint(for: $0, now: now) },
                notice: tonight?.notice?.headline,
                schedule: snapshot.schedule,
                now: now
            )
        )
    }
}
