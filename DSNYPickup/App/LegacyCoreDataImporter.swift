import CoreData
import DSNYKit
import Foundation

/// Moves favorites saved by version 1 of the app (Core Data, `GarbageCollection` entity) into SwiftData.
///
/// Runs once. The old store is opened read-only and left on disk so nothing is lost if the import
/// needs to be repeated by a future version.
@MainActor
enum LegacyCoreDataImporter {
    private static let completedKey = "legacyCoreDataImportCompleted"

    /// Where version 1 kept its SQLite store.
    private static var legacyStoreURL: URL? {
        SharedModelContainer.groupDirectory?.appending(path: "\(SharedModelContainer.appGroup).sqlite")
    }

    static func importIfNeeded(into store: AddressStore) async {
        let defaults = SharedModelContainer.defaults
        guard !defaults.bool(forKey: completedKey) else { return }

        guard let url = legacyStoreURL, FileManager.default.fileExists(atPath: url.path()) else {
            defaults.set(true, forKey: completedKey)
            return
        }

        guard let records = loadRecords(from: url) else {
            // Leave the flag unset so a later launch can try again.
            return
        }

        for record in records where !store.contains(formattedAddress: record.schedule.formattedAddress) {
            let address = store.add(record.schedule, queryAddress: record.schedule.formattedAddress)
            address.createdAt = record.savedDate ?? .now
            address.remindersEnabled = record.remindersEnabled
            address.reminderTiming = record.timing
            address.reminderMinutes = record.timing.defaultMinutes
        }
        store.saveChanges()

        // Replaces version 1's notifications (random identifiers, no address) with the new ones.
        await store.syncReminders()
        defaults.set(true, forKey: completedKey)
    }

    private struct LegacyRecord {
        let schedule: CollectionSchedule
        let savedDate: Date?
        let remindersEnabled: Bool
        let timing: ReminderTiming
    }

    private static func loadRecords(from url: URL) -> [LegacyRecord]? {
        guard let modelURL = Bundle.main.url(forResource: "GarbageCollection", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else { return nil }

        let container = NSPersistentContainer(name: "GarbageCollection", managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: url)
        description.isReadOnly = true
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        guard loadError == nil else { return nil }

        let request = NSFetchRequest<NSManagedObject>(entityName: "GarbageCollection")
        guard let objects = try? container.viewContext.fetch(request) else { return nil }

        return objects.compactMap { object in
            func string(_ key: String) -> String? { object.value(forKey: key) as? String }

            guard let formatted = string("formattedAddress"), !formatted.isEmpty else { return nil }
            let schedule = CollectionSchedule(
                formattedAddress: formatted,
                rawSchedules: [
                    .trash: string("regularCollectionSchedule") ?? "",
                    .recycling: string("recyclingCollectionSchedule") ?? "",
                    .compost: string("organicsCollectionSchedule") ?? "",
                    .bulk: string("bulkPickupCollectionSchedule") ?? ""
                ],
                residentialRoutingTime: string("residentialRoutingTime"),
                commercialRoutingTime: string("commercialRoutingTime"),
                mixedUseRoutingTime: string("mixedUseRoutingTime")
            )
            return LegacyRecord(
                schedule: schedule,
                savedDate: object.value(forKey: "savedDate") as? Date,
                remindersEnabled: object.value(forKey: "isNotificationsOn") as? Bool ?? false,
                // Version 1 stored "Day Of" or "Day Before".
                timing: string("frequencyOfDays") == "Day Before" ? .dayBefore : .dayOf
            )
        }
    }
}
