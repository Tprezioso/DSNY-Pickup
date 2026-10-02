import MapKit

/// An address suggestion from MapKit autocomplete.
struct AddressSuggestion: Identifiable, Hashable, Sendable {
    let title: String
    let subtitle: String

    var id: String { "\(title)|\(subtitle)" }

    /// The single-line address sent to DSNY, e.g. "125 Worth St, New York, NY 10013, United States".
    var query: String { subtitle.isEmpty ? title : "\(title), \(subtitle)" }
}

/// Wraps `MKLocalSearchCompleter`, limited to street addresses around New York City.
@MainActor
@Observable
final class AddressCompleter: NSObject {
    private(set) var suggestions: [AddressSuggestion] = []

    @ObservationIgnored private let completer = MKLocalSearchCompleter()

    /// Roughly the five boroughs.
    static let nycRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -73.9560),
        span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6)
    )

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        completer.region = Self.nycRegion
        completer.regionPriority = .required
    }

    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            completer.cancel()
            suggestions = []
        } else {
            completer.queryFragment = trimmed
        }
    }
}

extension AddressCompleter: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // DSNY only serves the five boroughs, so drop results elsewhere.
        let results = completer.results
            .filter { $0.subtitle.contains(", NY") || $0.subtitle.contains("New York") }
            .map { AddressSuggestion(title: $0.title, subtitle: $0.subtitle) }
        // The completer calls back on the main thread, where it was created.
        MainActor.assumeIsolated {
            suggestions = results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        MainActor.assumeIsolated {
            suggestions = []
        }
    }
}
