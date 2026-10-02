import AppIntents
import DSNYKit
import Foundation

/// "Turn on pickup reminders." Runs in the app so it goes through `AddressStore`,
/// which reschedules notifications and reloads widgets.
struct SetRemindersIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Pickup Reminders"
    static let description = IntentDescription(
        "Turns pickup reminders on or off for a saved address.",
        categoryName: "Reminders"
    )

    @Parameter(title: "Reminders", default: true, displayName: Bool.IntentDisplayName(true: "On", false: "Off"))
    var isEnabled: Bool

    @Parameter(title: "Address", description: "Leave empty to use your first saved address.")
    var address: AddressEntity?

    @Dependency private var store: AddressStore

    static var parameterSummary: some ParameterSummary {
        Summary("Turn reminders \(\.$isEnabled) for \(\.$address)")
    }

    init() {}

    init(isEnabled: Bool, address: AddressEntity? = nil) {
        self.isEnabled = isEnabled
        self.address = address
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let addresses = store.allAddresses()
        guard let saved = addresses.first(where: { $0.id == address?.id }) ?? addresses.first else {
            return .result(dialog: "You haven't saved an address yet. Open DSNY Pickup and add one first.")
        }

        saved.remindersEnabled = isEnabled
        store.saveChanges()
        await store.syncReminders()

        guard isEnabled else {
            return .result(dialog: "Pickup reminders are off for \(saved.displayName).")
        }
        if store.notificationsDenied {
            return .result(dialog: "Reminders are on for \(saved.displayName), but notifications are turned off for DSNY Pickup. Turn them on in Settings to get them.")
        }

        let time = Calendar.current.date(bySettingHour: saved.reminderMinutes / 60, minute: saved.reminderMinutes % 60, second: 0, of: .now) ?? .now
        let when = saved.reminderTiming == .dayBefore ? String(localized: "the night before") : String(localized: "the morning of")
        return .result(dialog: "Done. You'll get a reminder at \(time.formatted(date: .omitted, time: .shortened)) \(when) each pickup at \(saved.displayName).")
    }
}
