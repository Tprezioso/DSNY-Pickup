import AppIntents
import CoreSpotlight
import DSNYKit
import Foundation
import SwiftData
import UserNotifications
import WidgetKit

/// Owns every write to saved addresses so persistence, reminders and widgets stay in sync.
/// Views read addresses with `@Query` and call into this store to change them.
@MainActor
@Observable
final class AddressStore {
    let context: ModelContext
    private let scheduleService: ScheduleService
    private let reminders: ReminderScheduler
    private let serviceCalendarService: ServiceCalendarService?

    /// Holidays, delays and suspensions, from the last successful download.
    private(set) var serviceCalendar = ServiceCalendarService.cached()

    /// Set when a background refresh fails, so the UI can say it's showing saved data.
    private(set) var refreshError: DSNYError?
    /// `true` when the user has turned notifications off for the app in Settings.
    private(set) var notificationsDenied = false

    init(
        context: ModelContext,
        scheduleService: ScheduleService = ScheduleService(),
        reminders: ReminderScheduler = .shared,
        serviceCalendarService: ServiceCalendarService? = .fromBundle
    ) {
        self.context = context
        self.scheduleService = scheduleService
        self.reminders = reminders
        self.serviceCalendarService = serviceCalendarService
    }

    // MARK: Reading

    func allAddresses() -> [SavedAddress] {
        let descriptor = FetchDescriptor<SavedAddress>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Whether an address with the same DSNY-formatted address is already saved.
    func contains(formattedAddress: String) -> Bool {
        allAddresses().contains { $0.formattedAddress.caseInsensitiveCompare(formattedAddress) == .orderedSame }
    }

    // MARK: Writing

    /// Saves a new address at the end of the list. Returns the existing one if it's a duplicate.
    @discardableResult
    func add(_ schedule: CollectionSchedule, queryAddress: String) -> SavedAddress {
        if let existing = allAddresses().first(where: { $0.formattedAddress.caseInsensitiveCompare(schedule.formattedAddress) == .orderedSame }) {
            return existing
        }
        let nextOrder = (allAddresses().map(\.sortOrder).max() ?? -1) + 1
        let address = SavedAddress(schedule: schedule, queryAddress: queryAddress, sortOrder: nextOrder)
        context.insert(address)
        saveChanges()
        return address
    }

    func delete(_ address: SavedAddress) {
        let id = address.id
        Task { try? await CSSearchableIndex.default().deleteAppEntities(identifiedBy: [id], ofType: AddressEntity.self) }
        context.delete(address)
        saveChanges()
        Task { await syncReminders() }
    }

    /// Applies a new order from a list move.
    func move(_ addresses: [SavedAddress], from source: IndexSet, to destination: Int) {
        var reordered = addresses
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, address) in reordered.enumerated() {
            address.sortOrder = index
        }
        saveChanges()
    }

    /// Call after editing a label or reminder settings.
    func didEdit(_ address: SavedAddress) {
        saveChanges()
        Task { await syncReminders() }
    }

    // MARK: Refreshing

    /// Re-fetches one address's schedule from DSNY.
    func refresh(_ address: SavedAddress) async throws {
        let query = address.queryAddress.isEmpty ? address.formattedAddress : address.queryAddress
        let schedule = try await scheduleService.schedule(for: query)
        address.schedule = schedule
        saveChanges()
        await syncReminders()
    }

    /// Refreshes every address, keeping the saved schedule when the network fails.
    func refreshAll(onlyStale: Bool = false) async {
        var lastError: DSNYError?
        for address in allAddresses() where !onlyStale || address.needsRefresh() {
            do {
                try await refresh(address)
            } catch let error as DSNYError {
                lastError = error
            } catch {
                // Cancelled; leave the saved schedule as is.
            }
        }
        refreshError = lastError
    }

    // MARK: Reminders

    /// Pro service change alerts are on (they default to on once Pro is unlocked).
    static let serviceAlertsKey = "serviceAlertsEnabled"
    var serviceAlertsActive: Bool {
        let defaults = SharedModelContainer.defaults
        let enabled = defaults.object(forKey: Self.serviceAlertsKey) as? Bool ?? true
        return enabled && ProStatus.isPro && serviceCalendarService != nil
    }

    /// Asks for notification permission if needed, then reschedules every reminder and heads-up alert.
    func syncReminders() async {
        #if DEBUG
        // Screenshot mode uses demo data; never prompt for or schedule notifications.
        if ScreenshotMode.isActive { return }
        #endif
        let addresses = allAddresses()
        let alertsActive = serviceAlertsActive && !addresses.isEmpty
        if alertsActive || addresses.contains(where: \.remindersEnabled) {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined:
                notificationsDenied = !(await reminders.requestAuthorization())
            case .denied:
                notificationsDenied = true
            default:
                notificationsDenied = false
            }
        }
        let headsUps = alertsActive
            ? ServiceAlertPlanner.headsUps(for: addresses.map { AddressSnapshot($0) }, service: serviceCalendar)
            : []
        try? await reminders.sync(addresses.map(\.reminderPlan), service: serviceCalendar, extra: headsUps)
    }

    /// Run by the background refresh task: checks DSNY for new changes, alerts about newly announced
    /// ones (Pro), refreshes stale schedules, refills reminders and reloads widgets.
    func performBackgroundRefresh() async {
        let previous = serviceCalendar
        await refreshServiceCalendar(maxAge: 30 * 60)
        await refreshAll(onlyStale: true)
        await syncReminders()

        guard serviceAlertsActive, serviceCalendar != previous else { return }
        let addresses = allAddresses().map { AddressSnapshot($0) }
        for alert in ServiceAlertPlanner.breakingAlerts(old: previous, new: serviceCalendar, for: addresses) {
            try? await reminders.post(alert)
        }
    }

    // MARK: Service changes

    #if DEBUG
    /// Lets screenshot mode show a sample service change without downloading.
    func setServiceCalendarForScreenshots(_ calendar: ServiceCalendar) {
        serviceCalendar = calendar
    }
    #endif

    /// Downloads the latest holidays and delays when the cache is older than `maxAge`,
    /// then refreshes widgets. Keeps the cached calendar if the download fails.
    func refreshServiceCalendar(maxAge: TimeInterval = 6 * 60 * 60) async {
        guard let serviceCalendarService, Date.now.timeIntervalSince(serviceCalendar.fetchedAt) > maxAge else { return }
        guard let fresh = try? await serviceCalendarService.refresh() else { return }
        serviceCalendar = fresh
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
    }

    /// Saves pending edits and refreshes widgets, controls, Siri and Spotlight.
    func saveChanges() {
        do {
            try context.save()
        } catch {
            // SwiftData keeps unsaved changes in memory and retries on the next autosave.
        }
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
        Task { await indexForSpotlight() }
    }

    // MARK: Siri & Spotlight

    /// Indexes every address so Spotlight and Apple Intelligence can find it, and refreshes
    /// the address names Siri accepts in App Shortcut phrases.
    func indexForSpotlight() async {
        let entities = allAddresses().map { AddressSnapshot($0, service: serviceCalendar).entity() }
        try? await CSSearchableIndex.default().indexAppEntities(entities)
        DSNYPickupShortcuts.updateAppShortcutParameters()
    }
}
