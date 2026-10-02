import DSNYKit
import MapKit
import SwiftUI

/// Search for an address, preview its DSNY schedule, and save it.
struct AddAddressView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scheduleService) private var scheduleService
    @Environment(AddressStore.self) private var store

    @State private var query = ""
    @State private var completer = AddressCompleter()
    @State private var location = LocationProvider()
    @State private var phase: Phase = .searching
    @State private var lookupTask: Task<Void, Never>?
    @State private var didSave = false

    enum Phase {
        case searching
        case loading(String)
        case loaded(CollectionSchedule, query: String)
        case failed(DSNYError, query: String)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Add Address")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Street address")
                .onSubmit(of: .search) {
                    lookUp(query)
                }
                .onChange(of: query) { _, newValue in
                    completer.update(query: newValue)
                    if case .searching = phase {} else { phase = .searching }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                    }
                }
                .sensoryFeedback(.success, trigger: didSave)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .searching:
            suggestionList
        case .loading(let address):
            ProgressView("Looking up \(address)…")
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let schedule, let query):
            SchedulePreview(schedule: schedule, isDuplicate: store.contains(formattedAddress: schedule.formattedAddress)) {
                store.add(schedule, queryAddress: query)
                didSave.toggle()
                dismiss()
            }
        case .failed(let error, let query):
            ErrorStateView(error: error) { lookUp(query) }
        }
    }

    private var suggestionList: some View {
        List {
            if query.isEmpty {
                Section {
                    Button {
                        useCurrentLocation()
                    } label: {
                        Label("Use Current Location", systemImage: "location.fill")
                    }
                } footer: {
                    if location.isDenied {
                        Text("Location access is off. You can turn it on in Settings, or type your address.")
                    } else {
                        Text("Works for addresses in all five boroughs.")
                    }
                }
            }

            ForEach(completer.suggestions) { suggestion in
                Button {
                    lookUp(suggestion.query)
                } label: {
                    VStack(alignment: .leading) {
                        Text(suggestion.title)
                            .foregroundStyle(.primary)
                        Text(suggestion.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: Actions

    private func lookUp(_ address: String) {
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return }
        lookupTask?.cancel()
        phase = .loading(address)
        lookupTask = Task {
            do {
                let schedule = try await scheduleService.schedule(for: address)
                phase = .loaded(schedule, query: address)
            } catch is CancellationError {
                // A newer lookup replaced this one.
            } catch {
                phase = .failed(error.asDSNYError, query: address)
            }
        }
    }

    private func useCurrentLocation() {
        lookupTask?.cancel()
        phase = .loading(String(localized: "your location"))
        lookupTask = Task {
            guard let here = await location.currentLocation(),
                  let request = MKReverseGeocodingRequest(location: here),
                  let item = try? await request.mapItems.first,
                  let address = item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true) ?? item.address?.shortAddress else {
                phase = .searching
                return
            }
            lookUp(address)
        }
    }
}

/// The looked-up schedule with a save button.
private struct SchedulePreview: View {
    let schedule: CollectionSchedule
    let isDuplicate: Bool
    let save: () -> Void

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(schedule.formattedAddress)
                        .font(.headline)
                    WeekStripView(schedule: schedule)
                }
                .padding(.vertical, 4)
            }

            Section("Collection Days") {
                ForEach(CollectionStream.allCases) { stream in
                    StreamScheduleRow(stream: stream, schedule: schedule)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: save) {
                Label(isDuplicate ? "Already Saved" : "Save Address", systemImage: isDuplicate ? "checkmark" : "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(isDuplicate)
            .padding()
        }
    }
}

#Preview {
    AddAddressView()
        .environment(AddressStore.preview)
}
