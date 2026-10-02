import DSNYKit
import SwiftUI
import WidgetKit

/// The next seven days, one row per day, starting today.
struct WeekWidget: Widget {
    let kind = "DSNYPickupWeekWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectAddressIntent.self, provider: PickupProvider(requiresPro: true)) { entry in
            WeekView(entry: entry)
                .containerBackground(for: .widget) {
                    PickupBackground(stream: entry.next?.streams.first)
                }
                .widgetURL(entry.url)
        }
        .configurationDisplayName("Week at a Glance")
        .description("Every collection for the next seven days.")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
    }
}

struct WeekView: View {
    let entry: PickupEntry

    var body: some View {
        if entry.isLocked {
            ProLockedView(title: "Week at a Glance")
        } else if let address = entry.address {
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
                let scheduled = PickupCalendar.scheduledDays(address.schedule, from: entry.date, service: address.service)
                ForEach(days, id: \.self) { date in
                    let pickup = scheduled.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    DayRow(date: date, pickup: pickup, isToday: date == days.first)
                        .frame(maxHeight: .infinity)
                }
            }

            if let change = address.nextChange(from: entry.date), let notice = change.notice {
                WidgetNoticeText(pickup: change, notice: notice, now: entry.date)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            } else if let next = entry.next {
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
    let pickup: UpcomingPickup?
    let isToday: Bool

    private var streams: [CollectionStream] { pickup?.streams ?? [] }
    private var cancelled: [CollectionStream] { pickup?.cancelled ?? [] }

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

            if streams.isEmpty && cancelled.isEmpty {
                Text("No collection")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if renderingMode == .fullColor {
                // Full chips when they fit, otherwise just the icons. Cancelled streams are struck through.
                ViewThatFits(in: .horizontal) {
                    chips(showsTitles: true)
                    chips(showsTitles: false)
                }
            } else {
                Text(streams.isEmpty ? String(localized: "Cancelled") : streams.map { String(localized: $0.title) }.formatted(.list(type: .and)))
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .widgetAccentable()
            }
            Spacer(minLength: 0)
            if pickup?.notice != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .widgetAccentable()
            }
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

extension DayRow {
    private func chips(showsTitles: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(streams) { CompactChip(stream: $0, showsTitle: showsTitles) }
            ForEach(cancelled) { CompactChip(stream: $0, showsTitle: showsTitles, isCancelled: true) }
        }
    }
}

/// A smaller `StreamChip` that fits four to a row in a large widget.
private struct CompactChip: View {
    let stream: CollectionStream
    var showsTitle = true
    var isCancelled = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: stream.systemImage)
            if showsTitle { Text(stream.title).strikethrough(isCancelled) }
        }
        .font(.caption2.weight(.semibold))
        .lineLimit(1)
        .foregroundStyle(isCancelled ? Color.secondary : stream.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background((isCancelled ? Color.secondary : stream.color).opacity(0.15), in: .capsule)
        .opacity(isCancelled ? 0.7 : 1)
    }
}

#Preview(as: .systemLarge) {
    WeekWidget()
} timeline: {
    PickupEntry.placeholder
    PickupEntry(date: .now, address: AddressSnapshot(id: UUID(), name: "Home", shortAddress: "125 Worth St", schedule: .sample, service: .sampleHoliday(inDays: 2)))
    PickupEntry.empty
}
