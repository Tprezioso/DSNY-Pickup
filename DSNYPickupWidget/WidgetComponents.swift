import DSNYKit
import SwiftUI
import WidgetKit

/// A soft wash of the next pickup's first stream color, so the widget reads at a glance
/// (gray = trash, blue = recycling, brown = compost, orange = bulk).
struct PickupBackground: View {
    let stream: CollectionStream?

    var body: some View {
        ZStack {
            Color(.systemBackground)
            if let stream {
                LinearGradient(
                    colors: [stream.color.opacity(0.28), stream.color.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

/// Overlapping stream icons that turn into plain accented symbols on tinted and clear home screens.
struct StreamIconStack: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let streams: [CollectionStream]
    var size: CGFloat = 26

    var body: some View {
        HStack(spacing: renderingMode == .fullColor ? -size * 0.22 : 4) {
            ForEach(streams) { stream in
                if renderingMode == .fullColor {
                    StreamIcon(stream, size: size)
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                } else {
                    Image(systemName: stream.systemImage)
                        .font(.system(size: size * 0.6, weight: .semibold))
                        .widgetAccentable()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(streams.map { String(localized: $0.title) }.formatted(.list(type: .and)))
    }
}

/// The address name above a widget's headline.
struct AddressCaption: View {
    let name: String

    var body: some View {
        Label(name, systemImage: "house.fill")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

/// "Tonight", "Today" or "Tomorrow" headline that animates between timeline entries.
struct DayHeadline: View {
    let text: String
    var font: Font = .title.bold()

    var body: some View {
        Text(text)
            .font(font)
            .fontDesign(.rounded)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .contentTransition(.numericText())
            .widgetAccentable()
    }
}

/// Shown until the user saves an address in the app.
struct AddAddressPrompt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "house.badge.plus")
                .font(.title2)
                .foregroundStyle(.tint)
            Spacer(minLength: 0)
            Text("Add an address in DSNY Pickup to see your next pickup.")
                .font(.footnote.weight(.medium))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension UpcomingPickup {
    /// The headline for widgets: "Tonight" once it's past set-out time the day before.
    func headline(now: Date) -> String {
        switch PickupCalendar.countdown(to: self, from: now) {
        case .tonight: String(localized: "Tonight")
        default: PickupCalendar.relativeDayName(for: date, now: now)
        }
    }
}
