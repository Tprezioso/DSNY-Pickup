import DSNYKit
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(AddressStore.self) private var store
    @Environment(AppNavigator.self) private var navigator
    @Environment(PurchaseManager.self) private var purchases
    @Query(sort: [SortDescriptor(\SavedAddress.sortOrder), SortDescriptor(\SavedAddress.createdAt)])
    private var addresses: [SavedAddress]

    @State private var isAddingAddress = false

    var body: some View {
        @Bindable var navigator = navigator
        NavigationStack(path: $navigator.homePath) {
            Group {
                if addresses.isEmpty {
                    emptyState
                } else {
                    addressList
                }
            }
            .navigationTitle("Pickups")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Address", systemImage: "plus") {
                        // The first address is free; more need Pro.
                        if addresses.isEmpty || purchases.isPro {
                            isAddingAddress = true
                        } else {
                            navigator.showsPaywall = true
                        }
                    }
                }
                if addresses.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
            }
            .navigationDestination(for: SavedAddress.self) { address in
                AddressDetailView(address: address)
            }
            .sheet(isPresented: $isAddingAddress) {
                AddAddressView()
            }
            .task {
                await store.refreshAll(onlyStale: true)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Add Your Address", systemImage: "house")
        } description: {
            Text("See your trash, recycling, compost and bulk pickup days, and get a reminder the night before.")
        } actions: {
            Button("Add Address") {
                isAddingAddress = true
            }
            .buttonStyle(.glassProminent)
        }
    }

    private var addressList: some View {
        List {
            if let error = store.refreshError {
                Label {
                    Text(error == .offline ? "You're offline. Showing your saved schedules." : "Couldn't update from DSNY. Showing your saved schedules.")
                } icon: {
                    Image(systemName: error.systemImage)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            if let primary = addresses.first {
                Section {
                    NavigationLink(value: primary) {
                        NextPickupCard(name: primary.displayName, schedule: primary.schedule, service: store.serviceCalendar)
                    }
                } footer: {
                    StreamLegend()
                }
            }

            Section("Saved Addresses") {
                ForEach(addresses) { address in
                    NavigationLink(value: address) {
                        AddressRow(address: address)
                    }
                }
                .onDelete { offsets in
                    offsets.map { addresses[$0] }.forEach(store.delete)
                }
                .onMove { source, destination in
                    store.move(addresses, from: source, to: destination)
                }
            }
        }
        .refreshable {
            await store.refreshAll()
        }
    }
}

private struct AddressRow: View {
    @Environment(AddressStore.self) private var store
    let address: SavedAddress

    var body: some View {
        let next = PickupCalendar.next(address.schedule, service: store.serviceCalendar)
        let change = PickupCalendar.nextChange(address.schedule, service: store.serviceCalendar)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(address.displayName)
                    .font(.headline)
                if address.remindersEnabled {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Reminders on")
                }
            }
            if address.displayName != address.shortAddress {
                Text(address.shortAddress)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let notice = change?.notice {
                ServiceNoticeLabel(text: notice.headline)
                    .font(.caption.weight(.semibold))
            }
            if let next {
                HStack(spacing: 6) {
                    ForEach(next.streams) { StreamIcon($0, size: 20) }
                    Text("\(PickupCalendar.relativeDayName(for: next.date)): \(next.streamList)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    HomeView()
        .environment(AddressStore.preview)
        .environment(AppNavigator(store: AddressStore.preview))
        .environment(PurchaseManager())
        .modelContainer(AddressStore.preview.context.container)
}
