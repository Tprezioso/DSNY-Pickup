import DSNYKit
import SwiftUI

/// The hero card on Home: what's collected next, when to set it out, and the week at a glance.
struct NextPickupCard: View {
    let name: String
    let schedule: CollectionSchedule

    var body: some View {
        // Re-render at midnight so "Tomorrow" becomes "Today".
        // The first entry must be "now"; an explicit schedule renders its first date even if it's in the future.
        TimelineView(.explicit([Date.now] + PickupCalendar.midnights(after: .now, days: 7))) { context in
            content(now: context.date)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let next = PickupCalendar.next(schedule, from: now)

        VStack(alignment: .leading, spacing: 14) {
            Label(name, systemImage: "house.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if let next {
                VStack(alignment: .leading, spacing: 8) {
                    Text(PickupCalendar.relativeDayName(for: next.date, now: now))
                        .font(.largeTitle.bold())
                    FlowChips(streams: next.streams)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Next pickup \(PickupCalendar.relativeDayName(for: next.date, now: now)): \(next.streamList)")

                Text(PickupCalendar.setOutHint(for: next, now: now))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("No pickups this week")
                    .font(.title2.bold())
                Text("DSNY didn't return any collection days for this address.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            WeekStripView(schedule: schedule, today: Weekday(date: now))
        }
        .padding(.vertical, 6)
    }
}

/// Stream chips that wrap onto a second line when needed.
private struct FlowChips: View {
    let streams: [CollectionStream]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { chips }
            VStack(alignment: .leading) { chips }
        }
    }

    @ViewBuilder
    private var chips: some View {
        ForEach(streams) { StreamChip($0) }
    }
}

#Preview {
    List {
        NextPickupCard(name: "Home", schedule: .sample)
    }
}
