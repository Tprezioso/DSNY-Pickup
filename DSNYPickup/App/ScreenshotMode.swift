#if DEBUG
import DSNYKit
import Foundation

/// Deterministic setup for App Store screenshots. Debug builds only.
///
/// Launch with `-screenshotScreen <home|address|getRidOf|dropOffs|pro|more>`:
/// replaces saved addresses with demo ones (never a real person's address), unlocks Pro,
/// adds a sample collection delay on the next pickup, and opens the requested screen.
enum ScreenshotMode {
    static var screen: String? {
        UserDefaults.standard.string(forKey: "screenshotScreen")
    }

    static var isActive: Bool { screen != nil }

    @MainActor
    static func prepare(store: AddressStore, navigator: AppNavigator, purchases: PurchaseManager) {
        guard let screen else { return }
        store.loadDemoData()
        purchases.debugOverride = true

        switch screen {
        case "address":
            if let home = store.allAddresses().first { navigator.openAddress(id: home.id) }
        case "getRidOf": navigator.selectedTab = .getRidOf
        case "dropOffs": navigator.selectedTab = .dropOffs
        case "more": navigator.selectedTab = .more
        case "pro":
            navigator.selectedTab = .home
            navigator.showsPaywall = true
        default: navigator.selectedTab = .home
        }
    }
}

extension AddressStore {
    /// Two sample addresses and a weather delay on Home's next pickup after today.
    func loadDemoData() {
        for address in allAddresses() { context.delete(address) }

        let home = add(.sample, queryAddress: "125 Worth St, New York, NY")
        home.label = String(localized: "Home")
        home.remindersEnabled = true

        let office = add(
            CollectionSchedule(
                formattedAddress: "253 Broadway, New York, NY 10007, USA",
                rawSchedules: [.trash: "Monday,Wednesday,Friday", .recycling: "Wednesday", .compost: "Wednesday"]
            ),
            queryAddress: "253 Broadway, New York, NY"
        )
        office.label = String(localized: "Office")
        saveChanges()

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        if let next = PickupCalendar.next(.sample, from: tomorrow) {
            setServiceCalendarForScreenshots(.sampleHoliday(inDays: PickupCalendar.daysUntil(next.date), status: "DELAYED", name: nil))
        }
    }
}
#endif
