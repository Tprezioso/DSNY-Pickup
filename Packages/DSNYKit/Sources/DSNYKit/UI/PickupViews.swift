import SwiftUI

/// A stream's symbol in a tinted circle.
public struct StreamIcon: View {
    let stream: CollectionStream
    var size: CGFloat
    /// Grows the icon with Dynamic Type so it stays in proportion to the text beside it.
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    public init(_ stream: CollectionStream, size: CGFloat = 28) {
        self.stream = stream
        self.size = size
    }

    public var body: some View {
        // Capped so icons don't crowd out text at the largest accessibility sizes.
        let dimension = size * min(scale, 1.8)
        Image(systemName: stream.systemImage)
            .font(.system(size: dimension * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: dimension, height: dimension)
            .background(stream.color.gradient, in: .circle)
            .accessibilityHidden(true)
    }
}

/// A compact capsule with a stream's icon and name.
public struct StreamChip: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        // At accessibility sizes a name may need to wrap rather than push the layout off-screen.
        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
        .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: true)
        .foregroundStyle(stream.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(stream.color.opacity(0.15), in: .rect(cornerRadius: 16))
    }
}

/// Seven columns (in the user's week order) with a colored dot per stream collected that day.
/// Today is highlighted. At accessibility text sizes it becomes a list with one row per day,
/// since seven columns of large text can't fit across a phone.
public struct WeekStripView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let schedule: CollectionSchedule
    let today: Weekday
    var compact: Bool

    public init(schedule: CollectionSchedule, today: Weekday = Weekday(date: .now), compact: Bool = false) {
        self.schedule = schedule
        self.today = today
        self.compact = compact
    }

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            dayList
        } else {
            columns
        }
    }

    private var dayList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Weekday.ordered()) { day in
                let streams = schedule.streams(on: day)
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.name)
                        .font(.headline)
                        .foregroundStyle(day == today ? .primary : .secondary)
                    if streams.isEmpty {
                        Text("No collection")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(streams) { stream in
                            Label {
                                Text(stream.title)
                            } icon: {
                                Image(systemName: stream.systemImage)
                                    .foregroundStyle(stream.color)
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background {
                    if day == today {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.tint.opacity(0.15))
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var columns: some View {
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let streams: [CollectionStream]

    public init(streams: [CollectionStream] = CollectionStream.allCases) {
        self.streams = streams
    }

    public var body: some View {
        // Four items side by side don't fit at large sizes; the day list doesn't use dots, so hide it there.
        if !dynamicTypeSize.isAccessibilitySize {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { items }
                VStack(alignment: .leading, spacing: 4) { items }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var items: some View {
        ForEach(streams) { stream in
            HStack(spacing: 4) {
                Circle().fill(stream.color).frame(width: 8, height: 8)
                Text(stream.title)
            }
        }
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
