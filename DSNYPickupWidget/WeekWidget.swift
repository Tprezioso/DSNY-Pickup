import DSNYKit
import SwiftUI
import WidgetKit

/// The next seven days, one row per day, starting today.
struct WeekWidget: Widget {
    let kind = "DSNYPickupWeekWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectAddressIntent.self, provider: PickupProvider()) { entry in
            WeekView(entry: entry)
                .containerBackground(for: .widget) {
                    PickupBackground(stream: entry.next?.streams.first)
                }
                .widgetURL(entry.address.map { DeepLink.address($0.id).url })
        }
        .configurationDisplayName("Week at a Glance")
        .description("Every collection for the next seven days.")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
    }
}

struct WeekView: View {
    let entry: PickupEntry

    var body: some View {
        if let address = entry.address {
            content(address)
        } else {
            AddAddressPrompt()
        }
    }

    private func content(_ address: AddressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    AddressCaption(name: address.name)
                    Text("This Week")
                        .font(.title3.bold())
                        .fontDesign(.rounded)
                        .widgetAccentable()
                }
                Spacer()
                if let next = entry.next {
                    StreamIconStack(streams: next.streams, size: 24)
                }
            }

            // Rows share whatever height is left so seven days always fit without clipping.
            VStack(spacing: 2) {
                ForEach(days, id: \.self) { date in
                    DayRow(date: date, streams: address.schedule.streams(on: Weekday(date: date)), isToday: date == days.first)
                        .frame(maxHeight: .infinity)
                }
            }

            if let next = entry.next {
                Label(shortHint(for: next), systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    /// The full set-out hint doesn't fit on one line in a widget.
    private func shortHint(for pickup: UpcomingPickup) -> String {
        PickupCalendar.daysUntil(pickup.date, from: entry.date) == 0
            ? String(localized: "Collection today. Bring bins in after pickup.")
            : String(localized: "Set out after 6 PM the night before, in a lidded bin.")
    }

    private var days: [Date] {
        let start = Calendar.current.startOfDay(for: entry.date)
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }
}

private struct DayRow: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let date: Date
    let streams: [CollectionStream]
    let isToday: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(isToday ? String(localized: "Today") : Weekday(date: date).shortName)
                    .font(.subheadline.weight(.semibold))
                Text(date, format: .dateTime.day())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 64, alignment: .leading)

            if streams.isEmpty {
                Text("No collection")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if renderingMode == .fullColor {
                // Full chips when they fit, otherwise just the icons.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 4) { ForEach(streams) { CompactChip(stream: $0) } }
                    HStack(spacing: 4) { ForEach(streams) { CompactChip(stream: $0, showsTitle: false) } }
                }
            } else {
                Text(streams.map { String(localized: $0.title) }.formatted(.list(type: .and)))
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .widgetAccentable()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.primary.opacity(0.08))
            }
        }
    }
}

/// A smaller `StreamChip` that fits four to a row in a large widget.
private struct CompactChip: View {
    let stream: CollectionStream
    var showsTitle = true

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: stream.systemImage)
            if showsTitle { Text(stream.title) }
        }
        .font(.caption2.weight(.semibold))
        .lineLimit(1)
        .foregroundStyle(stream.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(stream.color.opacity(0.15), in: .capsule)
    }
}

#Preview(as: .systemLarge) {
    WeekWidget()
} timeline: {
    PickupEntry.placeholder
    PickupEntry.empty
}
