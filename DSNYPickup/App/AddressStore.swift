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

    /// Set when a background refresh fails, so the UI can say it's showing saved data.
    private(set) var refreshError: DSNYError?
    /// `true` when the user has turned notifications off for the app in Settings.
    private(set) var notificationsDenied = false

    init(context: ModelContext, scheduleService: ScheduleService = ScheduleService(), reminders: ReminderScheduler = .shared) {
        self.context = context
        self.scheduleService = scheduleService
        self.reminders = reminders
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

    /// Asks for notification permission if needed, then reschedules every reminder.
    func syncReminders() async {
        let addresses = allAddresses()
        if addresses.contains(where: \.remindersEnabled) {
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
        try? await reminders.sync(addresses.map(\.reminderPlan))
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
        let entities = allAddresses().map { AddressSnapshot($0).entity() }
        try? await CSSearchableIndex.default().indexAppEntities(entities)
        DSNYPickupShortcuts.updateAppShortcutParameters()
    }
}
