import CoreLocation

/// One-shot "where am I?" lookups using When In Use authorization.
@MainActor
@Observable
final class LocationProvider {
    /// The most recent fix, used to sort nearby drop-off sites.
    private(set) var location: CLLocation?
    /// `true` once the user has declined location access.
    private(set) var isDenied = false

    /// Returns the current location, prompting for permission the first time.
    /// Gives up after `timeout` so the UI never waits forever.
    func currentLocation(timeout: Duration = .seconds(10)) async -> CLLocation? {
        let result = await withTaskGroup(of: LocationResult.self) { group in
            group.addTask { await Self.firstUpdate() }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return .timedOut
            }
            let first = await group.next() ?? .timedOut
            group.cancelAll()
            return first
        }

        switch result {
        case .location(let location):
            self.location = location
            return location
        case .denied:
            isDenied = true
            return nil
        case .timedOut:
            return location
        }
    }

    private enum LocationResult: Sendable {
        case location(CLLocation)
        case denied
        case timedOut
    }

    private nonisolated static func firstUpdate() async -> LocationResult {
        // The session keeps When In Use authorization active (and prompts if needed) while updates run.
        let session = CLServiceSession(authorization: .whenInUse)
        defer { session.invalidate() }
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
                    return .denied
                }
                if let location = update.location {
                    return .location(location)
                }
            }
        } catch {
            return .timedOut
        }
        return .timedOut
    }
}
