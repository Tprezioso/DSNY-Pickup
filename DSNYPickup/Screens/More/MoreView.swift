import DSNYKit
import StoreKit
import SwiftUI

struct MoreView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(AppNavigator.self) private var navigator
    @Environment(AddressStore.self) private var store
    @AppStorage(AddressStore.serviceAlertsKey, store: SharedModelContainer.defaults) private var serviceAlertsEnabled = true

    var body: some View {
        NavigationStack {
            List {
                proSection
                alertsSection

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
                    ForEach(ProStatus.ProductID.tips, id: \.self) { id in
                        ProductView(id: id)
                            .productViewStyle(.compact)
                    }
                } header: {
                    Text("Tip Jar")
                } footer: {
                    Text("Tips don't unlock anything. They help keep DSNY Pickup independent and up to date. Thank you!")
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

    private var proSection: some View {
        Section {
            Button {
                navigator.showsPaywall = true
            } label: {
                LabeledContent {
                    Text(purchases.isPro ? "Unlocked" : "Upgrade")
                } label: {
                    Label("DSNY Pickup Pro", systemImage: "sparkles")
                }
            }
            Button("Restore Purchases", systemImage: "arrow.clockwise") {
                Task { await purchases.restore() }
            }
            #if DEBUG
            Picker("Debug: Pro", systemImage: "ladybug", selection: debugOverride) {
                Text("Real").tag(Bool?.none)
                Text("On").tag(Bool?.some(true))
                Text("Off").tag(Bool?.some(false))
            }
            #endif
        }
    }

    private var alertsSection: some View {
        Section {
            Toggle("Service Change Alerts", systemImage: "exclamationmark.triangle", isOn: alertsBinding)
        } footer: {
            Text("A heads-up two days before holidays that affect your pickups, plus alerts for snow delays and suspensions. iOS decides when the app can check, so short-notice changes may arrive a few hours late.")
        }
    }

    /// Without Pro the toggle reads off and opens the paywall.
    private var alertsBinding: Binding<Bool> {
        Binding {
            purchases.isPro && serviceAlertsEnabled
        } set: { isOn in
            guard purchases.isPro else {
                navigator.showsPaywall = true
                return
            }
            serviceAlertsEnabled = isOn
            Task { await store.syncReminders() }
        }
    }

    #if DEBUG
    private var debugOverride: Binding<Bool?> {
        Binding { purchases.debugOverride } set: { purchases.debugOverride = $0 }
    }
    #endif
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
        .environment(AddressStore.preview)
        .environment(PurchaseManager())
        .environment(AppNavigator(store: AddressStore.preview))
}
