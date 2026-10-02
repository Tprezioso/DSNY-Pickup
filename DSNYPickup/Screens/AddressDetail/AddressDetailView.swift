import DSNYKit
import MapKit
import SwiftUI

struct AddressDetailView: View {
    @Bindable var address: SavedAddress

    @Environment(AddressStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var isRefreshing = false
    @State private var refreshError: DSNYError?
    @State private var isConfirmingDelete = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(address.formattedAddress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    WeekStripView(schedule: address.schedule)
                }
                .padding(.vertical, 4)
            } footer: {
                StreamLegend()
            }

            Section("Collection Days") {
                ForEach(CollectionStream.allCases) { stream in
                    StreamScheduleRow(stream: stream, schedule: address.schedule)
                }
            }

            ReminderSettingsSection(address: address)

            routingSection

            Section {
                TextField("Nickname (e.g. Home)", text: $address.label)
                    .submitLabel(.done)
                    .onSubmit { store.didEdit(address) }
            } header: {
                Text("Nickname")
            }

            Section {
                Button("Open in Maps", systemImage: "map", action: openInMaps)
                Button {
                    Task { await refresh() }
                } label: {
                    if isRefreshing {
                        Label { Text("Refreshing…") } icon: { ProgressView() }
                    } else {
                        Label("Refresh Schedule", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
            } footer: {
                if let refreshError {
                    Text("Couldn't refresh: \(refreshError.errorDescription ?? "")")
                        .foregroundStyle(.red)
                } else {
                    Text("Updated \(address.lastRefreshed, format: .relative(presentation: .named)).")
                }
            }

            Section {
                Button("Remove Address", systemImage: "trash", role: .destructive) {
                    isConfirmingDelete = true
                }
            }
        }
        .navigationTitle(address.displayName)
        .confirmationDialog("Remove \(address.displayName)?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Remove Address", role: .destructive) {
                dismiss()
                store.delete(address)
            }
        } message: {
            Text("Its reminders will be turned off.")
        }
        .refreshable { await refresh() }
        .onDisappear { store.saveChanges() }
    }

    @ViewBuilder
    private var routingSection: some View {
        let schedule = address.schedule
        let rows: [(LocalizedStringKey, String)] = [
            ("Residential", schedule.residentialRoutingTime),
            ("Commercial", schedule.commercialRoutingTime),
            ("Mixed Use", schedule.mixedUseRoutingTime)
        ].compactMap { label, value in value.map { (label, $0) } }

        if !rows.isEmpty {
            Section {
                ForEach(rows, id: \.1) { label, value in
                    LabeledContent(label, value: value)
                }
            } header: {
                Text("DSNY Routing Times")
            } footer: {
                Text("As reported by DSNY for this address.")
            }
        }
    }

    private func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            try await store.refresh(address)
            refreshError = nil
        } catch {
            refreshError = error.asDSNYError
        }
    }

    private func openInMaps() {
        let query = address.formattedAddress
        Task {
            guard let request = MKGeocodingRequest(addressString: query),
                  let item = try? await request.mapItems.first else {
                if let url = URL(string: "maps://?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    openURL(url)
                }
                return
            }
            item.openInMaps()
        }
    }
}

#Preview {
    NavigationStack {
        AddressDetailView(address: AddressStore.preview.allAddresses()[0])
    }
    .environment(AddressStore.preview)
}
