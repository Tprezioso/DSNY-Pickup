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
#endif
