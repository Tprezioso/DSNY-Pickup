import DSNYKit
import SwiftUI
import WidgetKit

/// A Lock Screen gauge that fills as pickup day approaches: "3d" → "Tmrw" → "Tonight" → "Today".
struct CountdownWidget: Widget {
    let kind = "DSNYPickupCountdownWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectAddressIntent.self, provider: PickupProvider(requiresPro: true)) { entry in
            CountdownView(entry: entry)
                .containerBackground(for: .widget) { AccessoryWidgetBackground() }
                .widgetURL(entry.url)
        }
        .configurationDisplayName("Pickup Countdown")
        .description("Know at a glance whether bins go out tonight.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct CountdownView: View {
    let entry: PickupEntry

    var body: some View {
        if entry.isLocked {
            ProLockedView(title: "Pickup Countdown")
        } else if let next = entry.next {
            let countdown = PickupCalendar.countdown(to: next, from: entry.date)
            Gauge(value: countdown.progress) {
                Image(systemName: next.streams.first?.systemImage ?? "trash")
            } currentValueLabel: {
                VStack(spacing: 0) {
                    Image(systemName: next.streams.first?.systemImage ?? "trash")
                        .font(.caption2)
                    Text(countdown.shortLabel)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.6)
                }
            }
            .gaugeStyle(.accessoryCircular)
            .widgetAccentable()
            .accessibilityLabel("\(next.streamList) \(PickupCalendar.relativeDayName(for: next.date, now: entry.date))")
        } else {
            Image(systemName: entry.address == nil ? "house.badge.plus" : "calendar.badge.checkmark")
                .font(.title2)
        }
    }
}

#Preview(as: .accessoryCircular) {
    CountdownWidget()
} timeline: {
    PickupEntry.placeholder
    PickupEntry.empty
}
