import Foundation
import SwiftData

/// A read-only copy of a saved address, safe to pass around widgets and intents.
public struct AddressSnapshot: Sendable, Identifiable, Equatable {
    public let id: UUID
    /// The nickname, or the street part of the address.
    public let name: String
    public let shortAddress: String
    public let schedule: CollectionSchedule
    public let remindersEnabled: Bool
    /// Holidays and delays to apply, from the app group cache.
    public let service: ServiceCalendar

    public init(id: UUID, name: String, shortAddress: String, schedule: CollectionSchedule, remindersEnabled: Bool = false, service: ServiceCalendar = .empty) {
        self.id = id
        self.name = name
        self.shortAddress = shortAddress
        self.schedule = schedule
        self.remindersEnabled = remindersEnabled
        self.service = service
    }

    public init(_ address: SavedAddress, service: ServiceCalendar = .empty) {
        self.init(
            id: address.id,
            name: address.displayName,
            shortAddress: address.shortAddress,
            schedule: address.schedule,
            remindersEnabled: address.remindersEnabled,
            service: service
        )
    }

    /// The next collection day, including today, with holidays applied.
    public func next(from now: Date = .now) -> UpcomingPickup? {
        PickupCalendar.next(schedule, from: now, service: service)
    }

    /// Collection days in the next week, with holidays applied.
    public func upcoming(from now: Date = .now) -> [UpcomingPickup] {
        PickupCalendar.upcoming(schedule, from: now, service: service)
    }

    /// The first service change in the next week, for banners.
    public func nextChange(from now: Date = .now) -> UpcomingPickup? {
        PickupCalendar.nextChange(schedule, from: now, service: service)
    }

    /// Sample data for previews and the widget gallery.
    public static let sample = AddressSnapshot(
        id: UUID(uuidString: "6E1B9F4A-1D0E-4F43-9C38-1B2F3A5D7E01") ?? UUID(),
        name: String(localized: "Home"),
        shortAddress: "125 Worth St",
        schedule: .sample
    )
}

// MARK: - Reading the shared store

public extension AddressSnapshot {
    /// The app group store, opened once per process.
    private static let container = SharedModelContainer.make()

    /// Every saved address in the app's display order.
    static func all() -> [AddressSnapshot] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<SavedAddress>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)])
        let service = ServiceCalendarService.cached()
        return ((try? context.fetch(descriptor)) ?? []).map { AddressSnapshot($0, service: service) }
    }

    /// The address with `id`, or the primary (first) address when `id` is unset or was deleted.
    static func find(_ id: UUID?) -> AddressSnapshot? {
        let all = all()
        return all.first { $0.id == id } ?? all.first
    }
}
