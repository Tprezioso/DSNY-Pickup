import SwiftUI

/// DSNY's curbside rules, summarized from nyc.gov/dsny.
struct CollectionRulesView: View {
    private let holidays: [LocalizedStringKey] = [
        "New Year's Day", "Martin Luther King, Jr. Day", "Lincoln's Birthday", "Presidents' Day",
        "Memorial Day", "Juneteenth", "Independence Day", "Labor Day",
        "Columbus Day / Italian Heritage Day / Indigenous Peoples' Day", "Election Day",
        "Veterans Day", "Thanksgiving Day", "Christmas Day"
    ]

    var body: some View {
        List {
            Section {
                RuleRow(systemImage: "trash", title: "Buildings with 1–9 units",
                        detail: "Set trash out after 6 PM the night before, in a bin of 55 gallons or less with a secure lid.")
                RuleRow(systemImage: "building.2", title: "Buildings with 10+ units",
                        detail: "Set trash out after 6 PM in a lidded bin, or after 8 PM if putting bags directly on the curb.")
                RuleRow(systemImage: "clock", title: "Out by midnight",
                        detail: "To make sure it's collected, everything must be at the curb by midnight.")
            } header: {
                Text("Setting Out")
            }

            Section {
                RuleRow(systemImage: "house", title: "Store bins off the sidewalk",
                        detail: "Keep bins inside, in alleys or courtyards, or within three feet of your building, leaving room for pedestrians.")
                RuleRow(systemImage: "exclamationmark.bubble", title: "Missed collection",
                        detail: "Report it to 311 starting at 8 AM the day after your scheduled collection.")
            } header: {
                Text("After Collection")
            }

            Section {
                ForEach(Array(holidays.enumerated()), id: \.offset) { _, holiday in
                    Text(holiday)
                }
            } header: {
                Text("Recognized Holidays")
            } footer: {
                Text("Holiday service can change. If your collection day falls on a holiday, check DSNY's holiday schedule or 311.")
            }
        }
        .navigationTitle("Collection Rules")
    }
}

private struct RuleRow: View {
    let systemImage: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        CollectionRulesView()
    }
}
