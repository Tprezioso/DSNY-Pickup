import AppIntents
import CoreSpotlight
import Foundation

/// A saved address as Siri, Shortcuts, Spotlight and widget configuration see it.
///
/// Properties carry the next pickup so Apple Intelligence and the Shortcuts "Use Model" action
/// can answer follow-up questions without another round trip.
public struct AddressEntity: IndexedEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Address",
        numericFormat: "\(placeholder: .int) addresses"
    )
    public static let defaultQuery = AddressQuery()

    /// `SavedAddress.id`, which is stable across launches.
    public let id: UUID

    @Property(title: "Name")
    public var name: String

    @Property(title: "Street Address")
    public var address: String

    @Property(title: "Next Pickup Date")
    public var nextPickupDate: Date?

    @Property(title: "Next Pickup Collections")
    public var nextPickupStreams: [CollectionStream]

    @Property(title: "Weekly Schedule")
    public var scheduleSummary: String

    public init(id: UUID, name: String, address: String, nextPickup: UpcomingPickup?, scheduleSummary: String) {
        self.id = id
        self.name = name
        self.address = address
        self.nextPickupDate = nextPickup?.date
        self.nextPickupStreams = nextPickup?.streams ?? []
        self.scheduleSummary = scheduleSummary
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(address)", image: .init(systemName: "house.fill"))
    }

    public var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.contentDescription = scheduleSummary
        attributes.keywords = ["trash", "garbage", "recycling", "compost", "bulk", "pickup", "DSNY", address]
        return attributes
    }
}

public extension AddressSnapshot {
    /// The entity for this address, with its next pickup computed from `now`.
    func entity(now: Date = .now) -> AddressEntity {
        AddressEntity(id: id, name: name, address: shortAddress, nextPickup: next(from: now), scheduleSummary: scheduleSummary)
    }

    /// "Trash: Tue, Thu, Sat. Recycling: Sat." — a plain-text week for Siri and Spotlight.
    var scheduleSummary: String {
        CollectionStream.allCases.compactMap { stream in
            let days = schedule.days(for: stream)
            if !days.isEmpty { return "\(String(localized: stream.title)): \(days.shortList)." }
            if let text = schedule.unparsedText(for: stream) { return "\(String(localized: stream.title)): \(text)." }
            return nil
        }
        .joined(separator: " ")
    }
}

public struct AddressQuery: EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [UUID]) async throws -> [AddressEntity] {
        AddressSnapshot.all().filter { identifiers.contains($0.id) }.map { $0.entity() }
    }

    public func entities(matching string: String) async throws -> [AddressEntity] {
        AddressSnapshot.all()
            .filter { $0.name.localizedStandardContains(string) || $0.shortAddress.localizedStandardContains(string) }
            .map { $0.entity() }
    }

    public func suggestedEntities() async throws -> [AddressEntity] {
        AddressSnapshot.all().map { $0.entity() }
    }

    public func defaultResult() async -> AddressEntity? {
        AddressSnapshot.all().first?.entity()
    }
}

/// Picks which saved address a widget shows.
public struct SelectAddressIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "Choose Address"
    public static let description = IntentDescription("Choose which saved address the widget shows.")

    @Parameter(title: "Address")
    public var address: AddressEntity?

    public init() {}

    public init(address: AddressEntity?) {
        self.address = address
    }
}
