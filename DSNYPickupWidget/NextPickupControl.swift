import AppIntents
import DSNYKit
import SwiftUI
import WidgetKit

/// A Control Center / Lock Screen / Action button control showing the next pickup.
/// Tapping it opens the app on that address.
struct NextPickupControl: ControlWidget {
    static let kind = "com.Swifttom.DSNYPickup.NextPickupControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: Self.kind, provider: Provider()) { value in
            ControlWidgetButton(action: OpenAddressIntent(target: value.entity)) {
                Label {
                    Text(value.title)
                    Text(value.subtitle)
                } icon: {
                    Image(systemName: value.systemImage)
                }
            }
        }
        .displayName("Next Pickup")
        .description("See your next trash, recycling or compost pickup.")
    }
}

extension NextPickupControl {
    struct Value {
        let entity: AddressEntity
        let title: String
        let subtitle: String
        let systemImage: String

        init(_ address: AddressSnapshot, now: Date = .now) {
            let next = address.next(from: now)
            entity = address.entity(now: now)
            title = next?.headline(now: now) ?? String(localized: "No pickups")
            subtitle = next?.streamList ?? address.name
            systemImage = next?.streams.first?.systemImage ?? "calendar"
        }

        /// Shown before any address is saved; opening it just launches the app.
        static let noAddress = Value(placeholder: String(localized: "Add an address"))

        private init(placeholder: String) {
            entity = AddressSnapshot.sample.entity()
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
            AddressSnapshot.find(configuration.address?.id).map { Value($0) } ?? .noAddress
        }
    }
}

struct SelectAddressControlIntent: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Address"

    @Parameter(title: "Address")
    var address: AddressEntity?

    init() {}
}
