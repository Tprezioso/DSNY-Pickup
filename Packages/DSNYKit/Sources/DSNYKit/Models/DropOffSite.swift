import CoreLocation
import Foundation

/// A place NYC residents can drop off items DSNY won't collect at the curb.
public struct DropOffSite: Sendable, Hashable, Identifiable {
    public enum Kind: String, CaseIterable, Sendable, Identifiable {
        case specialWaste
        case electronics
        case foodScraps

        public var id: String { rawValue }

        public var title: LocalizedStringResource {
            switch self {
            case .specialWaste: "Special Waste"
            case .electronics: "Electronics"
            case .foodScraps: "Food Scraps"
            }
        }

        public var systemImage: String {
            switch self {
            case .specialWaste: "exclamationmark.triangle.fill"
            case .electronics: "desktopcomputer"
            case .foodScraps: "carrot.fill"
            }
        }

        /// NYC Open Data (Socrata) dataset identifier.
        var datasetID: String {
            switch self {
            case .specialWaste: "242c-ru4i"
            case .electronics: "wshr-5vic"
            case .foodScraps: "if26-z6xq"
            }
        }
    }

    public let id: String
    public let kind: Kind
    public let name: String
    public let address: String
    public let borough: String?
    public let latitude: Double
    public let longitude: Double
    public let hours: String?
    public let notes: String?
    public let website: URL?

    public init(
        id: String,
        kind: Kind,
        name: String,
        address: String,
        borough: String?,
        latitude: Double,
        longitude: Double,
        hours: String? = nil,
        notes: String? = nil,
        website: URL? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.address = address
        self.borough = borough
        self.latitude = latitude
        self.longitude = longitude
        self.hours = hours
        self.notes = notes
        self.website = website
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Open Data rows

/// A GeoJSON point as Socrata returns it: `{"type":"Point","coordinates":[lon, lat]}`.
struct SocrataPoint: Decodable {
    let coordinates: [Double]

    var latitude: Double? { coordinates.count == 2 ? coordinates[1] : nil }
    var longitude: Double? { coordinates.count == 2 ? coordinates[0] : nil }
}

/// Columns shared by the three DSNY drop-off datasets. Every field is optional because
/// Socrata omits empty columns from a row.
struct DropOffRow: Decodable {
    // Special waste
    let fid: String?
    let name: String?
    let boro: String?
    let city: String?
    let zip: String?
    let point: SocrataPoint?
    // Electronics
    let objectid: String?
    let dropoffSitename: String?
    let zipcode: String?
    // Food scraps
    let objectId: String?
    let foodScrapDropOffSite: String?
    let location: String?
    let locationPoint: SocrataPoint?
    let operationDayHours: String?
    let openMonths: String?
    let notes: String?
    let website: String?
    // Shared
    let address: String?
    let borough: String?
    let latitude: String?
    let longitude: String?

    enum CodingKeys: String, CodingKey {
        case fid, name, boro, city, zip, point, objectid, zipcode, location, notes, website, address, borough, latitude, longitude
        case dropoffSitename = "dropoff_sitename"
        case objectId = "object_id"
        case foodScrapDropOffSite = "food_scrap_drop_off_site"
        case locationPoint = "location_point"
        case operationDayHours = "operation_day_hours"
        case openMonths = "open_months"
    }

    /// DSNY borough codes used by the special waste dataset.
    private static let boroughCodes = ["1": "Manhattan", "2": "Bronx", "3": "Brooklyn", "4": "Queens", "5": "Staten Island"]

    func site(kind: DropOffSite.Kind) -> DropOffSite? {
        let lat = latitude.flatMap(Double.init) ?? point?.latitude ?? locationPoint?.latitude
        let lon = longitude.flatMap(Double.init) ?? point?.longitude ?? locationPoint?.longitude
        guard let lat, let lon else { return nil }

        let borough = borough.nonEmpty ?? boro.flatMap { Self.boroughCodes[$0] }
        let street = address.nonEmpty ?? location.nonEmpty ?? ""
        // Append city and ZIP unless the street text already includes them (food scrap rows often do).
        let extras = [city.nonEmpty ?? borough, zip.nonEmpty ?? zipcode.nonEmpty]
            .compactMap { $0 }
            .filter { !street.localizedCaseInsensitiveContains($0) }
        let fullAddress = ([street] + extras).filter { !$0.isEmpty }.joined(separator: ", ")

        let hours = [operationDayHours.nonEmpty, openMonths.nonEmpty].compactMap { $0 }.joined(separator: " · ")
        let websiteURL = website.nonEmpty.flatMap { URL(string: $0.hasPrefix("http") ? $0 : "https://\($0)") }

        return DropOffSite(
            id: "\(kind.rawValue)-\(fid ?? objectid ?? objectId ?? "\(lat),\(lon)")",
            kind: kind,
            name: name.nonEmpty ?? dropoffSitename.nonEmpty ?? foodScrapDropOffSite.nonEmpty ?? String(localized: "Drop-Off Site"),
            address: fullAddress,
            borough: borough,
            latitude: lat,
            longitude: lon,
            hours: hours.isEmpty ? nil : hours,
            notes: notes.nonEmpty,
            website: websiteURL
        )
    }
}
