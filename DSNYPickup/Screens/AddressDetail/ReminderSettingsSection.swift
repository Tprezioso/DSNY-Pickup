import DSNYKit
import SwiftUI
import UIKit

/// Reminder toggle, timing, time of day and which streams to include.
struct ReminderSettingsSection: View {
    @Bindable var address: SavedAddress
    @Environment(AddressStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            Toggle("Pickup Reminders", systemImage: "bell.badge", isOn: $address.remindersEnabled)

            if address.remindersEnabled && !purchases.isPro {
                // Free reminders use the saved settings (7 PM the night before, every collection by default).
                Button {
                    navigator.showsPaywall = true
                } label: {
                    Label("Customize Time & Collections", systemImage: "sparkles")
                }
            } else if address.remindersEnabled {
                Picker("Remind Me", selection: timing) {
                    ForEach(ReminderTiming.allCases) { timing in
                        Text(timing.title).tag(timing)
                    }
                }
                .pickerStyle(.segmented)

                DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)

                ForEach(CollectionStream.allCases) { stream in
                    Toggle(isOn: includes(stream)) {
                        Label {
                            Text(stream.title)
                        } icon: {
                            StreamIcon(stream, size: 24)
                        }
                    }
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            if address.remindersEnabled && store.notificationsDenied {
                Button("Notifications are turned off for DSNY Pickup. Open Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.footnote)
            } else if address.remindersEnabled {
                Text("One notification for each pickup day, listing everything collected that day.")
            }
        }
        .onChange(of: address.remindersEnabled) { store.didEdit(address) }
        .onChange(of: address.reminderTimingRaw) { store.didEdit(address) }
        .onChange(of: address.reminderMinutes) { store.didEdit(address) }
        .onChange(of: address.reminderStreamsRaw) { store.didEdit(address) }
    }

    // MARK: Bindings

    private var timing: Binding<ReminderTiming> {
        Binding {
            address.reminderTiming
        } set: { newValue in
            // Move the time to a sensible default when switching between evening and morning.
            if newValue != address.reminderTiming {
                address.reminderMinutes = newValue.defaultMinutes
            }
            address.reminderTiming = newValue
        }
    }

    private var time: Binding<Date> {
        Binding {
            Calendar.current.startOfDay(for: .now).addingTimeInterval(TimeInterval(address.reminderMinutes * 60))
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            address.reminderMinutes = (parts.hour ?? 19) * 60 + (parts.minute ?? 0)
        }
    }

    private func includes(_ stream: CollectionStream) -> Binding<Bool> {
        Binding {
            address.reminderStreams.contains(stream)
        } set: { isOn in
            var streams = address.reminderStreams
            if isOn { streams.insert(stream) } else { streams.remove(stream) }
            address.reminderStreams = streams
        }
    }
}
