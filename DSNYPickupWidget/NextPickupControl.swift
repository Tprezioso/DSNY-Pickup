import AppIntents
import DSNYKit
import SwiftUI
import WidgetKit

/// A Control Center / Lock Screen / Action button control showing the next pickup.
/// Tapping it opens the app on that address (or the paywall, without Pro).
struct NextPickupControl: ControlWidget {
    static let kind = "com.Swifttom.DSNYPickup.NextPickupControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: Self.kind, provider: Provider()) { value in
            ControlWidgetButton(action: ControlTapIntent(addressID: value.addressID, showsPaywall: value.isLocked)) {
                Label {
                    Text(value.isLocked ? String(localized: "Next Pickup") : value.title)
                    Text(value.isLocked ? String(localized: "Unlock with Pro") : value.subtitle)
                } icon: {
                    Image(systemName: value.isLocked ? "lock.fill" : value.systemImage)
                }
            }
        }
        .displayName("Next Pickup")
        .description("See your next trash, recycling or compost pickup.")
    }
}

extension NextPickupControl {
    struct Value {
        let addressID: UUID?
        let title: String
        let subtitle: String
        let systemImage: String
        var isLocked = false

        init(_ address: AddressSnapshot, now: Date = .now) {
            let next = address.next(from: now)
            addressID = address.id
            title = next?.headline(now: now) ?? String(localized: "No pickups")
            subtitle = next?.streamList ?? address.name
            systemImage = next?.streams.first?.systemImage ?? "calendar"
        }

        /// Shown before any address is saved; opening it just launches the app.
        static let noAddress = Value(placeholder: String(localized: "Add an address"))

        private init(placeholder: String) {
            addressID = nil
            title = String(localized: "DSNY Pickup")
            subtitle = placeholder
            systemImage = "house.badge.plus"
        }
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: SelectAddressControlIntent) -> Value {
            Value(.sample)
        }

        func currentValue(configuration: SelectAddressControlIntent) async throws -> Value {
            var value = AddressSnapshot.find(configuration.address?.id).map { Value($0) } ?? .noAddress
            value.isLocked = !ProStatus.isPro
            return value
        }
    }
}

struct SelectAddressControlIntent: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Address"

    @Parameter(title: "Address")
    var address: AddressEntity?

    init() {}
}
