import DSNYKit
import SwiftUI

/// One stream's collection days, e.g. "Recycling · Saturday · Next: Tomorrow".
struct StreamScheduleRow: View {
    let stream: CollectionStream
    let schedule: CollectionSchedule

    var body: some View {
        let days = schedule.days(for: stream)
        HStack(spacing: 12) {
            StreamIcon(stream, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(stream.title)
                    .font(.headline)
                Group {
                    if !days.isEmpty {
                        Text(days.count == 1 ? days.first?.name ?? "" : days.shortList)
                    } else if let text = schedule.unparsedText(for: stream) {
                        Text(text)
                    } else {
                        Text("No scheduled collection")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if let next = PickupCalendar.nextDate(for: stream, in: schedule) {
                Text(PickupCalendar.relativeDayName(for: next))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(stream.color)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        ForEach(CollectionStream.allCases) {
            StreamScheduleRow(stream: $0, schedule: .sample)
        }
    }
}
