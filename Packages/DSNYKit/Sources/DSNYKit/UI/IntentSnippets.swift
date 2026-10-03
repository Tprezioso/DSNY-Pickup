import SwiftUI

/// The card Siri and Shortcuts show with a pickup answer.
public struct PickupSnippetView: View {
    let addressName: String
    let headline: String
    let streams: [CollectionStream]
    let hint: String?
    let notice: String?
    let schedule: CollectionSchedule
    let today: Weekday

    public init(addressName: String, headline: String, streams: [CollectionStream], hint: String?, notice: String? = nil, schedule: CollectionSchedule, now: Date = .now) {
        self.addressName = addressName
        self.headline = headline
        self.streams = streams
        self.hint = hint
        self.notice = notice
        self.schedule = schedule
        self.today = Weekday(date: now)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Label(addressName, systemImage: "house.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(headline)
                        .font(.title2.bold())
                }
                Spacer(minLength: 0)
                HStack(spacing: -6) {
                    ForEach(streams) { StreamIcon($0, size: 34) }
                }
            }

            if let notice {
                ServiceNoticeLabel(text: notice)
            }

            if !streams.isEmpty {
                HStack(spacing: 6) {
                    ForEach(streams) { StreamChip($0) }
                }
            }

            if let hint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            WeekStripView(schedule: schedule, today: today, compact: true)
        }
        .padding()
    }
}

/// An orange callout for holidays and delays, shared by the app, widgets and Siri.
public struct ServiceNoticeLabel: View {
    let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        // Orange text on white fails contrast guidelines, so only the icon carries the color.
        Label {
            Text(text)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
        .font(.subheadline.weight(.semibold))
    }
}

/// The card Siri shows for a "how do I get rid of …" answer.
public struct DisposalSnippetView: View {
    let item: String
    let category: String
    let lines: [String]

    public init(item: String, category: String, lines: [String]) {
        self.item = item
        self.category = category
        self.lines = lines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(category, systemImage: "arrow.3.trianglepath")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(item)
                .font(.title3.bold())
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

#Preview("Pickup") {
    PickupSnippetView(
        addressName: "Home",
        headline: "Tomorrow",
        streams: [.trash, .recycling],
        hint: "Set out after 6 PM the night before in a lidded bin.",
        schedule: .sample
    )
}

#Preview("Disposal") {
    DisposalSnippetView(item: "Mattresses", category: "Furniture, Mattresses, & Rugs", lines: ["Put mattresses out for bulk collection.", "Seal them in a plastic bag first."])
}
