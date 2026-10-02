import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CollectionRulesView()
                    } label: {
                        Label("Collection Rules", systemImage: "list.bullet.clipboard")
                    }
                    ExternalLink("Holiday Schedule", systemImage: "calendar.badge.exclamationmark", url: Links.holidays)
                }

                Section {
                    ExternalLink("Report a Problem to 311", systemImage: "exclamationmark.bubble", url: Links.portal311)
                    if let call = Links.call311 {
                        Link(destination: call) {
                            Label("Call 311", systemImage: "phone")
                        }
                    }
                } header: {
                    Text("311")
                } footer: {
                    Text("Report a missed collection starting at 8 AM the day after your scheduled pickup.")
                }

                Section("DSNY") {
                    ExternalLink("Trash Rules & Bins", systemImage: "trash", url: Links.trash)
                    ExternalLink("SAFE Disposal Events", systemImage: "cross.vial", url: Links.safeEvents)
                    ExternalLink("DSNY Website", systemImage: "safari", url: Links.dsny)
                }

                Section {
                    LabeledContent("Version", value: Bundle.main.versionString)
                    if let email = Links.email {
                        Link(destination: email) {
                            Label("Send Feedback", systemImage: "envelope")
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("DSNY Pickup is an unofficial app and isn't affiliated with the NYC Department of Sanitation. Schedules come from DSNY, and drop-off sites come from NYC Open Data. Always check nyc.gov/dsny for service changes.")
                }
            }
            .navigationTitle("More")
        }
    }
}

private enum Links {
    static let holidays = URL(string: "https://www.nyc.gov/site/dsny/collection/residents/holiday-schedule.page")
    static let portal311 = URL(string: "https://portal.311.nyc.gov/")
    static let call311 = URL(string: "tel:311")
    static let trash = URL(string: "https://www.nyc.gov/site/dsny/collection/residents/trash.page")
    static let safeEvents = URL(string: "https://www.nyc.gov/site/dsny/what-we-do/programs/safe-disposal-events.page")
    static let dsny = URL(string: "https://www.nyc.gov/site/dsny/index.page")
    static let email = URL(string: "mailto:tommyprezioso@gmail.com?subject=DSNY%20Pickup%20Feedback")
}

/// A row that opens a web page, skipped if the URL is malformed.
private struct ExternalLink: View {
    let title: LocalizedStringKey
    let systemImage: String
    let url: URL?

    init(_ title: LocalizedStringKey, systemImage: String, url: URL?) {
        self.title = title
        self.systemImage = systemImage
        self.url = url
    }

    var body: some View {
        if let url {
            Link(destination: url) {
                Label(title, systemImage: systemImage)
            }
        }
    }
}

private extension Bundle {
    var versionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }
}

#Preview {
    MoreView()
}
