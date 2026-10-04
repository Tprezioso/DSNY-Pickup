import DSNYKit
import SwiftData

extension AddressStore {
    /// An in-memory store with one sample address, for previews.
    @MainActor
    static let preview: AddressStore = {
        let container = SharedModelContainer.make(inMemory: true)
        let store = AddressStore(context: container.mainContext)
        let address = store.add(.sample, queryAddress: "125 Worth St, New York, NY")
        address.label = "Home"
        return store
    }()
}
