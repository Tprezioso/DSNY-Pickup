import Foundation
import SwiftData

/// The SwiftData container shared by the app and widget through the app group.
public enum SharedModelContainer {
    public static let appGroup = "group.com.Swifttom.DSNYPickup"

    /// Directory shared by the app and its extensions, or `nil` when the entitlement is missing (tests, previews).
    public static var groupDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    /// Defaults shared with the widget.
    public static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    /// Creates the container. Falls back to an in-memory store rather than crashing if the
    /// on-disk store can't be opened, so the app always launches.
    public static func make(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([SavedAddress.self])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let directory = groupDirectory {
            configuration = ModelConfiguration(schema: schema, url: directory.appending(path: "DSNYPickup.store"))
        } else {
            configuration = ModelConfiguration(schema: schema)
        }

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // In-memory configuration creation only fails for an invalid schema, which is a programmer error.
            return try! ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        }
    }
}
