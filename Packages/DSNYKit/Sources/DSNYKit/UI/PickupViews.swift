import SwiftUI

/// A stream's symbol in a tinted circle.
public struct StreamIcon: View {
    let stream: CollectionStream
    var size: CGFloat

    public init(_ stream: CollectionStream, size: CGFloat = 28) {
        self.stream = stream
        self.size = size
    }

    public var body: some View {
        Image(systemName: stream.systemImage)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(stream.color.gradient, in: .circle)
            .accessibilityHidden(true)
    }
}

/// A compact capsule with a stream's icon and name.
public struct StreamChip: View {
    let stream: CollectionStream

    public init(_ stream: CollectionStream) {
        self.stream = stream
    }

    public var body: some View {
        // An explicit HStack rather than Label, which some containers collapse to icon-only.
        HStack(spacing: 4) {
            Image(systemName: stream.systemImage)
            Text(stream.title)
        }
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
        .fixedSize()
        .foregroundStyle(stream.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(stream.color.opacity(0.15), in: .capsule)
    }
}

/// Seven columns (in the user's week order) with a colored dot per stream collected that day.
/// Today is highlighted.
public struct WeekStripView: View {
    let schedule: CollectionSchedule
    let today: Weekday
    var compact: Bool

    public init(schedule: CollectionSchedule, today: Weekday = Weekday(date: .now), compact: Bool = false) {
        self.schedule = schedule
        self.today = today
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: compact ? 2 : 6) {
            ForEach(Weekday.ordered()) { day in
                let streams = schedule.streams(on: day)
                VStack(spacing: compact ? 3 : 6) {
                    Text(compact ? day.initial : day.shortName)
                        .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                        .foregroundStyle(day == today ? .primary : .secondary)
                    VStack(spacing: 3) {
                        ForEach(streams) { stream in
                            Circle()
                                .fill(stream.color)
                                .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)
                        }
                    }
                    .frame(minHeight: compact ? 24 : 38, alignment: .top)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 4 : 8)
                .background {
                    if day == today {
                        RoundedRectangle(cornerRadius: compact ? 8 : 12)
                            .fill(.tint.opacity(0.15))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(day.name)
                .accessibilityValue(streams.isEmpty ? String(localized: "No collection") : streams.map { String(localized: $0.title) }.formatted(.list(type: .and)))
            }
        }
    }
}

/// A legend explaining the week strip's dot colors.
public struct StreamLegend: View {
    let streams: [CollectionStream]

    public init(streams: [CollectionStream] = CollectionStream.allCases) {
        self.streams = streams
    }

    public var body: some View {
        HStack(spacing: 12) {
            ForEach(streams) { stream in
                HStack(spacing: 4) {
                    Circle().fill(stream.color).frame(width: 8, height: 8)
                    Text(stream.title)
                }
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 20) {
        WeekStripView(schedule: .sample, today: .thursday)
        WeekStripView(schedule: .sample, today: .thursday, compact: true)
        StreamLegend()
        HStack { ForEach(CollectionStream.allCases) { StreamIcon($0) } }
        HStack { StreamChip(.trash); StreamChip(.recycling) }
    }
    .padding()
}
