import DSNYKit
import SwiftUI

/// The hero card on Home: what's collected next, when to set it out, and the week at a glance.
struct NextPickupCard: View {
    let name: String
    let schedule: CollectionSchedule
    var service: ServiceCalendar = .empty

    var body: some View {
        // Re-render at midnight so "Tomorrow" becomes "Today".
        // The first entry must be "now"; an explicit schedule renders its first date even if it's in the future.
        TimelineView(.explicit([Date.now] + PickupCalendar.midnights(after: .now, days: 7))) { context in
            content(now: context.date)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let next = PickupCalendar.next(schedule, from: now, service: service)
        let change = PickupCalendar.nextChange(schedule, from: now, service: service)

        VStack(alignment: .leading, spacing: 14) {
            Label(name, systemImage: "house.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if let change, let notice = change.notice {
                ServiceChangeBanner(pickup: change, notice: notice, now: now)
            }

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

/// "Thursday: Thanksgiving Day — No collection. Keep your bins in." shown above the next pickup.
private struct ServiceChangeBanner: View {
    let pickup: UpcomingPickup
    let notice: ServiceNotice
    let now: Date

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: notice.isDelay ? "clock.badge.exclamationmark.fill" : "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(PickupCalendar.relativeDayName(for: pickup.date, now: now)): \(notice.headline)")
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var message: String {
        if pickup.isFullyCancelled {
            return String(localized: "Keep your bins in. Collection resumes on the next scheduled day.")
        }
        if notice.isDelay {
            return notice.details ?? String(localized: "Leave your bins out until they're collected.")
        }
        let off = pickup.cancelled.map { String(localized: $0.title) }.formatted(.list(type: .and))
        return String(localized: "\(off) won't be collected. Everything else is on schedule.")
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
        NextPickupCard(
            name: "Home",
            schedule: .sample,
            service: .sampleHoliday(inDays: 2)
        )
    }
}
