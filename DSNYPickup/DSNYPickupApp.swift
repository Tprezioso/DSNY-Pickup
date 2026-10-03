//
//  DSNYPickupApp.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import AppIntents
import BackgroundTasks
import DSNYKit
import StoreKit
import SwiftData
import SwiftUI

@main
struct DSNYPickupApp: App {
    private let container: ModelContainer
    @State private var store: AddressStore
    @State private var navigator: AppNavigator
    @State private var purchases = PurchaseManager()
    @Environment(\.scenePhase) private var scenePhase

    static let refreshTaskID = "com.Swifttom.DSNYPickup.refresh"

    init() {
        let container = SharedModelContainer.make()
        let store = AddressStore(context: container.mainContext)
        self.container = container
        _store = State(initialValue: store)
        _navigator = State(initialValue: AppNavigator(store: store))
        // Lets intents that change data (e.g. SetRemindersIntent) go through the same store as the UI.
        AppDependencyManager.shared.add(dependency: store)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(navigator)
                .environment(purchases)
                .onInAppPurchaseCompletion { _, result in
                    if case .success(.success(let verification)) = result {
                        await purchases.handle(verification)
                    }
                }
                .onChange(of: purchases.isPro) {
                    #if DEBUG
                    // Screenshot mode unlocks Pro; don't trigger a notification permission prompt.
                    if ScreenshotMode.isActive { return }
                    #endif
                    // Turning Pro on or off adds or removes service alerts.
                    Task { await store.syncReminders() }
                }
                .onOpenURL { url in
                    if let link = DeepLink(url: url) { navigator.open(link) }
                }
                .onAppIntentExecution(OpenAddressIntent.self) { intent in
                    navigator.openAddress(id: intent.target.id)
                }
                .onAppIntentExecution(ControlTapIntent.self) { intent in
                    if intent.showsPaywall {
                        navigator.showsPaywall = true
                    } else if let id = intent.addressID.flatMap(UUID.init(uuidString:)) {
                        navigator.openAddress(id: id)
                    }
                }
                .task {
                    await purchases.refresh()
                    #if DEBUG
                    if ScreenshotMode.isActive {
                        ScreenshotMode.prepare(store: store, navigator: navigator, purchases: purchases)
                        return
                    }
                    #endif
                    // One-time import of favorites saved by the Core Data version of the app.
                    await LegacyCoreDataImporter.importIfNeeded(into: store)
                    await store.refreshServiceCalendar()
                    // Reminders are dated over a rolling window, so top them up on every launch.
                    await store.syncReminders()
                    await store.indexForSpotlight()
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { Self.scheduleRefresh() }
        }
        .backgroundTask(.appRefresh(Self.refreshTaskID)) { @MainActor in
            Self.scheduleRefresh()
            await store.performBackgroundRefresh()
        }
    }

    /// Asks iOS to wake the app in a few hours to check for holidays and snow delays.
    /// iOS decides the actual time based on how the app is used.
    static func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = .now.addingTimeInterval(3 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
