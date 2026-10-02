import AppIntents
import DSNYKit
import WidgetKit

/// Makes the intents and entities in DSNYKit available to widget configuration and controls.
struct DSNYPickupWidgetIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [DSNYKitIntentsPackage.self] }
}

/// When widgets need to redraw: each midnight ("Tomorrow" → "Today") and each 6 PM set-out time
/// ("Tomorrow" → "Tonight"), for a week.
enum PickupTimeline {
    static func dates(from now: Date, calendar: Calendar = .current) -> [Date] {
        let midnights = PickupCalendar.midnights(after: now, days: 7, calendar: calendar)
        let setOutTimes = ([calendar.startOfDay(for: now)] + midnights).compactMap {
            calendar.date(bySettingHour: PickupCalendar.setOutHour, minute: 0, second: 0, of: $0)
        }
        return [now] + (midnights + setOutTimes).filter { $0 > now }.sorted()
    }

    static func policy(for dates: [Date]) -> TimelineReloadPolicy {
        .after(dates.last ?? .now.addingTimeInterval(86_400))
    }
}

// MARK: - Single address

struct PickupEntry: TimelineEntry {
    let date: Date
    /// `nil` when the user hasn't saved an address yet.
    let address: AddressSnapshot?

    var next: UpcomingPickup? { address?.next(from: date) }

    static let placeholder = PickupEntry(date: .now, address: .sample)
    static let empty = PickupEntry(date: .now, address: nil)
}

struct PickupProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PickupEntry {
        .placeholder
    }

    func snapshot(for configuration: SelectAddressIntent, in context: Context) async -> PickupEntry {
        let address = AddressSnapshot.find(configuration.address?.id)
        // Show sample data in the widget gallery before anything is saved.
        if address == nil && context.isPreview { return .placeholder }
        return PickupEntry(date: .now, address: address)
    }

    func timeline(for configuration: SelectAddressIntent, in context: Context) async -> Timeline<PickupEntry> {
        let address = AddressSnapshot.find(configuration.address?.id)
        let dates = PickupTimeline.dates(from: .now)
        return Timeline(entries: dates.map { PickupEntry(date: $0, address: address) }, policy: PickupTimeline.policy(for: dates))
    }
}

// MARK: - Every address

struct AddressesEntry: TimelineEntry {
    let date: Date
    let addresses: [AddressSnapshot]

    static let placeholder = AddressesEntry(date: .now, addresses: [
        .sample,
        AddressSnapshot(
            id: UUID(),
            name: String(localized: "Office"),
            shortAddress: "253 Broadway",
            schedule: CollectionSchedule(formattedAddress: "253 Broadway", rawSchedules: [.trash: "Monday,Wednesday,Friday", .recycling: "Wednesday"])
        ),
        AddressSnapshot(
            id: UUID(),
            name: String(localized: "Mom's"),
            shortAddress: "4 Court Sq",
            schedule: CollectionSchedule(formattedAddress: "4 Court Sq", rawSchedules: [.trash: "Monday,Thursday", .recycling: "Thursday", .compost: "Thursday"])
        )
    ])
}

struct AddressesProvider: TimelineProvider {
    func placeholder(in context: Context) -> AddressesEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (AddressesEntry) -> Void) {
        let addresses = AddressSnapshot.all()
        completion(addresses.isEmpty && context.isPreview ? .placeholder : AddressesEntry(date: .now, addresses: addresses))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AddressesEntry>) -> Void) {
        let addresses = AddressSnapshot.all()
        let dates = PickupTimeline.dates(from: .now)
        completion(Timeline(entries: dates.map { AddressesEntry(date: $0, addresses: addresses) }, policy: PickupTimeline.policy(for: dates)))
    }
}
