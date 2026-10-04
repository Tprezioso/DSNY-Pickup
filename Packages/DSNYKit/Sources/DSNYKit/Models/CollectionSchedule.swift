import Foundation

/// The collection schedule for a single NYC address.
public struct CollectionSchedule: Sendable, Equatable, Codable {
    public var formattedAddress: String
    /// Raw schedule text per stream as returned by DSNY, e.g. "Tuesday,Thursday,Saturday".
    public var rawSchedules: [CollectionStream: String]
    public var residentialRoutingTime: String?
    public var commercialRoutingTime: String?
    public var mixedUseRoutingTime: String?

    public init(
        formattedAddress: String,
        rawSchedules: [CollectionStream: String],
        residentialRoutingTime: String? = nil,
        commercialRoutingTime: String? = nil,
        mixedUseRoutingTime: String? = nil
    ) {
        self.formattedAddress = formattedAddress
        self.rawSchedules = rawSchedules
        self.residentialRoutingTime = residentialRoutingTime
        self.commercialRoutingTime = commercialRoutingTime
        self.mixedUseRoutingTime = mixedUseRoutingTime
    }

    /// Days the given stream is collected.
    public func days(for stream: CollectionStream) -> Set<Weekday> {
        Weekday.parseList(rawSchedules[stream])
    }

    /// Text for streams whose schedule isn't a plain list of days (e.g. "Call 311"), otherwise `nil`.
    public func unparsedText(for stream: CollectionStream) -> String? {
        guard let raw = rawSchedules[stream]?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        return days(for: stream).isEmpty ? raw : nil
    }

    /// Streams collected on `weekday`, in display order.
    public func streams(on weekday: Weekday) -> [CollectionStream] {
        CollectionStream.allCases.filter { days(for: $0).contains(weekday) }
    }

    /// `true` when DSNY returned no usable days for any stream.
    public var isEmpty: Bool {
        CollectionStream.allCases.allSatisfy { days(for: $0).isEmpty }
    }
}

// MARK: - API response

/// Wire format of `DSNYGeoCoder/api/DSNYCollection/CollectionSchedule`. Only the fields the app uses are decoded.
struct CollectionScheduleResponse: Decodable {
    struct RoutingTime: Decodable {
        let commercialRoutingTime: String?
        let residentialRoutingTime: String?
        let mixedUseRoutingTime: String?

        enum CodingKeys: String, CodingKey {
            case commercialRoutingTime = "CommercialRoutingTime"
            case residentialRoutingTime = "ResidentialRoutingTime"
            case mixedUseRoutingTime = "MixedUseRoutingTime"
        }
    }

    let formattedAddress: String?
    let routingTime: RoutingTime?
    let regularCollectionSchedule: String?
    let recyclingCollectionSchedule: String?
    let organicsCollectionSchedule: String?
    let bulkPickupCollectionSchedule: String?

    enum CodingKeys: String, CodingKey {
        case formattedAddress = "FormattedAddress"
        case routingTime = "RoutingTime"
        case regularCollectionSchedule = "RegularCollectionSchedule"
        case recyclingCollectionSchedule = "RecyclingCollectionSchedule"
        case organicsCollectionSchedule = "OrganicsCollectionSchedule"
        case bulkPickupCollectionSchedule = "BulkPickupCollectionSchedule"
    }

    /// Converts the response to a schedule, or `nil` when DSNY couldn't match the address
    /// (the API answers 200 with every field `null` in that case).
    func schedule() -> CollectionSchedule? {
        guard let formattedAddress, !formattedAddress.isEmpty else { return nil }
        var raw: [CollectionStream: String] = [:]
        raw[.trash] = regularCollectionSchedule
        raw[.recycling] = recyclingCollectionSchedule
        raw[.compost] = organicsCollectionSchedule
        raw[.bulk] = bulkPickupCollectionSchedule
        return CollectionSchedule(
            formattedAddress: formattedAddress,
            rawSchedules: raw,
            residentialRoutingTime: routingTime?.residentialRoutingTime.nonEmpty,
            commercialRoutingTime: routingTime?.commercialRoutingTime.nonEmpty,
            mixedUseRoutingTime: routingTime?.mixedUseRoutingTime.nonEmpty
        )
    }
}

extension Optional<String> {
    /// The trimmed string, or `nil` when it's missing or blank.
    var nonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
