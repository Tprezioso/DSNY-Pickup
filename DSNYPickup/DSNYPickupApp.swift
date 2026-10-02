//
//  DSNYPickupApp.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import AppIntents
import DSNYKit
import SwiftData
import SwiftUI

@main
struct DSNYPickupApp: App {
    private let container: ModelContainer
    @State private var store: AddressStore
    @State private var navigator: AppNavigator

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
                .onOpenURL { url in
                    if let link = DeepLink(url: url) { navigator.open(link) }
                }
                .onAppIntentExecution(OpenAddressIntent.self) { intent in
                    navigator.openAddress(id: intent.target.id)
                }
                .task {
                    // One-time import of favorites saved by the Core Data version of the app.
                    await LegacyCoreDataImporter.importIfNeeded(into: store)
                    await store.indexForSpotlight()
                }
        }
        .modelContainer(container)
    }
}
