import DSNYKit
import SwiftUI
import WidgetKit

/// The next pickup at every saved address.
struct AllAddressesWidget: Widget {
    let kind = "DSNYPickupAllAddressesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AddressesProvider()) { entry in
            AllAddressesView(entry: entry)
                .containerBackground(Color(.systemBackground), for: .widget)
                .widgetURL(entry.isLocked ? DeepLink.pro.url : DeepLink.home.url)
        }
        .configurationDisplayName("All Addresses")
        .description("The next pickup at each of your saved addresses.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct AllAddressesView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AddressesEntry

    var body: some View {
        if entry.isLocked {
            ProLockedView(title: "All Addresses")
        } else if entry.addresses.isEmpty {
            AddAddressPrompt()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("Next Pickups")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.bottom, 6)

                ForEach(Array(visible.enumerated()), id: \.element.id) { index, address in
                    if index > 0 { Divider().padding(.vertical, 4) }
                    Link(destination: DeepLink.address(address.id).url) {
                        AddressRow(address: address, now: entry.date)
                    }
                }

                Spacer(minLength: 0)

                if hiddenCount > 0 {
                    Text("+\(hiddenCount) more in the app")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var capacity: Int { family == .systemLarge ? 6 : 3 }
    private var visible: [AddressSnapshot] { Array(entry.addresses.prefix(capacity)) }
    private var hiddenCount: Int { max(0, entry.addresses.count - capacity) }
}

private struct AddressRow: View {
    let address: AddressSnapshot
    let now: Date

    var body: some View {
        let next = address.next(from: now)
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(address.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let change = address.nextChange(from: now), let notice = change.notice {
                    WidgetNoticeText(pickup: change, notice: notice, now: now)
                        .font(.caption)
                        .lineLimit(1)
                } else {
                    Text(next?.streamList ?? String(localized: "No pickups this week"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if let next {
                StreamIconStack(streams: next.streams, size: 20)
                Text(next.headline(now: now))
                    .font(.subheadline.weight(.bold))
                    .fontDesign(.rounded)
                    .contentTransition(.numericText())
                    .widgetAccentable()
                    .frame(minWidth: 64, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview(as: .systemMedium) {
    AllAddressesWidget()
} timeline: {
    AddressesEntry.placeholder
    AddressesEntry(date: .now, addresses: [])
}

#Preview(as: .systemLarge) {
    AllAddressesWidget()
} timeline: {
    AddressesEntry.placeholder
}
