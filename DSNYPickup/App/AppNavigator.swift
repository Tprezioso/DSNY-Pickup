import DSNYKit
import Foundation
import SwiftData

/// Tab selection and Home's navigation stack, so widget taps and Siri can open a specific address.
@MainActor
@Observable
final class AppNavigator {
    var selectedTab: RootView.Section = .home
    var homePath: [SavedAddress] = []

    private let store: AddressStore

    init(store: AddressStore) {
        self.store = store
    }

    func open(_ link: DeepLink) {
        switch link {
        case .home:
            selectedTab = .home
            homePath = []
        case .address(let id):
            openAddress(id: id)
        }
    }

    /// Shows the address's detail screen on Home. Falls back to Home's list if it was deleted.
    func openAddress(id: UUID) {
        selectedTab = .home
        homePath = store.allAddresses().first { $0.id == id }.map { [$0] } ?? []
    }
}
