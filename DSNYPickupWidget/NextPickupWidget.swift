//
//  NextPickupWidget.swift
//  DSNYPickupWidget
//
//  Created by Thomas Prezioso Jr on 3/29/23.
//

import DSNYKit
import SwiftUI
import WidgetKit

struct NextPickupWidget: Widget {
    /// Unchanged from the original widget so placed widgets keep working after updating.
    let kind = "DSNYPickupWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectAddressIntent.self, provider: PickupProvider()) { entry in
            NextPickupView(entry: entry)
                // Widgets have a fixed size; past this, text would be clipped rather than readable.
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                .containerBackground(for: .widget) {
                    PickupBackground(stream: entry.next?.streams.first)
                }
                .widgetURL(entry.url)
        }
        .configurationDisplayName("Next Pickup")
        .description("See what's collected next at your address and when to set it out.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct NextPickupView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PickupEntry

    var body: some View {
        if let address = entry.address {
            switch family {
            case .accessoryInline: inline
            case .accessoryRectangular: rectangular(address)
            case .systemMedium: medium(address)
            default: small(address)
            }
        } else {
            switch family {
            case .accessoryInline, .accessoryRectangular: Text("Add an address in DSNY Pickup")
            default: AddAddressPrompt()
            }
        }
    }

    // MARK: Lock Screen

    @ViewBuilder
    private var inline: some View {
        if let next = entry.next {
            Label("\(next.headline(now: entry.date)): \(next.streamList)", systemImage: next.streams.first?.systemImage ?? "trash")
        } else {
            Label("No pickups this week", systemImage: "calendar")
        }
    }

    private func rectangular(_ address: AddressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            if let next = entry.next {
                HStack(spacing: 4) {
                    ForEach(next.streams) { Image(systemName: $0.systemImage) }
                    Text(next.headline(now: entry.date))
                }
                .font(.headline)
                .widgetAccentable()
                Text(next.streamList)
                    .font(.caption)
                    .lineLimit(2)
            } else {
                Text("No pickups this week")
                    .font(.headline)
            }
            if let notice = address.nextChange(from: entry.date)?.notice {
                Label(notice.headline, systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .lineLimit(1)
            } else {
                Text(address.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Home Screen

    private func small(_ address: AddressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            AddressCaption(name: address.name)
            Spacer(minLength: 0)
            if let next = entry.next {
                StreamIconStack(streams: next.streams, size: 30)
                    .padding(.bottom, 2)
                DayHeadline(text: next.headline(now: entry.date))
                if let change = address.nextChange(from: entry.date), let notice = change.notice {
                    // A holiday or delay matters more than the usual set-out hint.
                    WidgetNoticeText(pickup: change, notice: notice, now: entry.date)
                } else {
                    Text(footer(for: next))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            } else {
                DayHeadline(text: String(localized: "No pickups"), font: .title3.bold())
                Text("this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func medium(_ address: AddressSnapshot) -> some View {
        HStack(alignment: .top, spacing: 16) {
            small(address)

            VStack(alignment: .leading, spacing: 8) {
                Text("Coming Up")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                let later = address.upcoming(from: entry.date).dropFirst().prefix(3)
                if later.isEmpty {
                    Text("Nothing else this week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(later)) { pickup in
                    HStack(spacing: 8) {
                        Text(Weekday(date: pickup.date).shortName)
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 36, alignment: .leading)
                        StreamIconStack(streams: pickup.streams, size: 20)
                        Spacer(minLength: 0)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func footer(for pickup: UpcomingPickup) -> String {
        switch PickupCalendar.countdown(to: pickup, from: entry.date) {
        case .tonight: String(localized: "Set out for tomorrow: \(pickup.streamList)")
        case .tomorrow: String(localized: "Set out after 6 PM tonight")
        default: pickup.streamList
        }
    }
}

#Preview(as: .systemSmall) {
    NextPickupWidget()
} timeline: {
    PickupEntry.placeholder
    PickupEntry.empty
}

#Preview(as: .systemMedium) {
    NextPickupWidget()
} timeline: {
    PickupEntry.placeholder
}

#Preview(as: .accessoryRectangular) {
    NextPickupWidget()
} timeline: {
    PickupEntry.placeholder
}
