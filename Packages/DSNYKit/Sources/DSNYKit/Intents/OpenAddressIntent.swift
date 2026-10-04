#if os(iOS)
import AppIntents
import Foundation

/// Opens the app on a saved address. Shared so widgets and Control Center can run it;
/// the app handles navigation with `onAppIntentExecution(OpenAddressIntent.self)`.
public struct OpenAddressIntent: OpenIntent, TargetContentProvidingIntent {
    public static let title: LocalizedStringResource = "Open Address"
    public static let description = IntentDescription("Opens DSNY Pickup on a saved address's schedule.", categoryName: "Pickups")

    @Parameter(title: "Address")
    public var target: AddressEntity

    public init() {}

    public init(target: AddressEntity) {
        self.target = target
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        .result()
    }
}

/// What tapping the Next Pickup control does: open an address, or the Pro paywall when the control is locked.
/// Control templates can't branch, so both cases share one intent type. Hidden from Shortcuts and Siri.
public struct ControlTapIntent: AppIntent, TargetContentProvidingIntent {
    public static let title: LocalizedStringResource = "Open DSNY Pickup"
    public static let openAppWhenRun = true
    public static let isDiscoverable = false

    @Parameter(title: "Address ID")
    public var addressID: String?

    @Parameter(title: "Show Pro", default: false)
    public var showsPaywall: Bool

    public init() {}

    public init(addressID: UUID?, showsPaywall: Bool) {
        self.addressID = addressID?.uuidString
        self.showsPaywall = showsPaywall
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        .result()
    }
}
#endif
