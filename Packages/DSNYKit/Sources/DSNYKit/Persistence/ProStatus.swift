import Foundation

/// Whether DSNY Pickup Pro is unlocked, shared through the app group so widgets and intents can check it.
/// The app's purchase manager is the only writer.
public enum ProStatus {
    private static let key = "proUnlocked"

    public static var isPro: Bool {
        SharedModelContainer.defaults.bool(forKey: key)
    }

    public static func set(_ isPro: Bool) {
        SharedModelContainer.defaults.set(isPro, forKey: key)
    }

    /// Product identifiers, matching App Store Connect and `Products.storekit`.
    public enum ProductID {
        public static let pro = "com.Swifttom.DSNYPickup.pro"
        public static let tips = [
            "com.Swifttom.DSNYPickup.tip.small",
            "com.Swifttom.DSNYPickup.tip.medium",
            "com.Swifttom.DSNYPickup.tip.large"
        ]
    }

    /// The last build released before Pro existed. People who first installed this build or earlier
    /// keep every feature they already had.
    public static let lastFreeBuild = 5

    /// Whether `originalAppVersion` (the build number of the first install on iOS) predates Pro.
    /// Unparseable values (e.g. "1.0" in the sandbox) are not grandfathered.
    public static func isGrandfathered(originalBuild: String) -> Bool {
        guard let build = Int(originalBuild.trimmingCharacters(in: .whitespaces)) else { return false }
        return build <= lastFreeBuild
    }
}

/// What Pro adds, used for paywall copy.
public enum ProFeature: String, CaseIterable, Identifiable, Sendable {
    case multipleAddresses
    case extraWidgets
    case serviceAlerts
    case customReminders
    case siriActions

    public var id: String { rawValue }

    public var title: LocalizedStringResource {
        switch self {
        case .multipleAddresses: "Unlimited Addresses"
        case .extraWidgets: "Every Widget"
        case .serviceAlerts: "Service Change Alerts"
        case .customReminders: "Custom Reminders"
        case .siriActions: "Siri Actions"
        }
    }

    public var subtitle: LocalizedStringResource {
        switch self {
        case .multipleAddresses: "Home, work, your parents' place, and the All Addresses widget."
        case .extraWidgets: "Week at a Glance, Lock Screen countdown, and Control Center."
        case .serviceAlerts: "A heads-up before holidays, and alerts for snow delays and suspensions."
        case .customReminders: "Morning-of reminders, any time you like, and per-collection choices."
        case .siriActions: "Turn reminders on or off with your voice or in Shortcuts."
        }
    }

    public var systemImage: String {
        switch self {
        case .multipleAddresses: "house.and.flag.fill"
        case .extraWidgets: "square.grid.2x2.fill"
        case .serviceAlerts: "exclamationmark.triangle.fill"
        case .customReminders: "bell.badge.fill"
        case .siriActions: "waveform"
        }
    }
}
