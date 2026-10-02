import DSNYKit
import MapKit
import SwiftUI

/// Special waste, electronics and food scrap drop-off sites from NYC Open Data.
struct DropOffsView: View {
    @Environment(\.dropOffService) private var service

    @State private var kind: DropOffSite.Kind = .specialWaste
    @State private var sitesByKind: [DropOffSite.Kind: [DropOffSite]] = [:]
    @State private var error: DSNYError?
    @State private var isLoading = false
    @State private var selection: DropOffSite.ID?
    @State private var position: MapCameraPosition = .region(AddressCompleter.nycRegion)
    @State private var location = LocationProvider()
    @Namespace private var glassNamespace

    private var sites: [DropOffSite] {
        let sites = sitesByKind[kind] ?? []
        guard let here = location.location else { return sites }
        return sites.sorted { $0.location.distance(from: here) < $1.location.distance(from: here) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                map
                    .frame(height: 300)
                    .overlay(alignment: .top) { kindPicker }
                siteList
            }
            .navigationTitle("Drop-Offs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Sort by Distance", systemImage: "arrow.up.arrow.down") {
                        Task {
                            _ = await location.currentLocation()
                        }
                    }
                }
            }
            .sheet(item: selectedSite) { site in
                DropOffSiteSheet(site: site, distance: distance(to: site))
                    .presentationDetents([.medium])
            }
            .task(id: kind) { await load(kind) }
        }
    }

    // MARK: Subviews

    private var map: some View {
        Map(position: $position, selection: $selection) {
            ForEach(sites) { site in
                Marker(site.name, systemImage: kind.systemImage, coordinate: site.coordinate)
                    .tint(kind.color)
                    .tag(site.id)
            }
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        // Keep the map's own controls clear of the filter chips overlaid at the top.
        .safeAreaPadding(.top, 52)
    }

    private var kindPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(DropOffSite.Kind.allCases) { option in
                        Button {
                            withAnimation { kind = option }
                        } label: {
                            Label(option.title, systemImage: option.systemImage)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(option == kind ? .regular.tint(option.color).interactive() : .regular.interactive())
                        .glassEffectID(option, in: glassNamespace)
                        .accessibilityAddTraits(option == kind ? .isSelected : [])
                    }
                }
                .padding(.horizontal)
            }
        }
        .scrollClipDisabled()
        .padding(.top, 8)
    }

    @ViewBuilder
    private var siteList: some View {
        if let error, sites.isEmpty {
            ErrorStateView(error: error) { Task { await load(kind, force: true) } }
        } else if isLoading && sites.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(sites) { site in
                Button {
                    selection = site.id
                } label: {
                    SiteRow(site: site, distance: distance(to: site))
                }
                .tint(.primary)
            }
            .listStyle(.plain)
            .overlay {
                if sites.isEmpty {
                    ContentUnavailableView("No Sites", systemImage: kind.systemImage)
                }
            }
        }
    }

    // MARK: Helpers

    private var selectedSite: Binding<DropOffSite?> {
        Binding {
            sites.first { $0.id == selection }
        } set: { site in
            selection = site?.id
        }
    }

    private func distance(to site: DropOffSite) -> Measurement<UnitLength>? {
        guard let here = location.location else { return nil }
        return Measurement(value: site.location.distance(from: here), unit: .meters)
    }

    private func load(_ kind: DropOffSite.Kind, force: Bool = false) async {
        guard force || sitesByKind[kind] == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            sitesByKind[kind] = try await service.sites(kind)
            error = nil
        } catch is CancellationError {
            // Switched kinds mid-load.
        } catch {
            self.error = error.asDSNYError
        }
    }
}

private struct SiteRow: View {
    let site: DropOffSite
    let distance: Measurement<UnitLength>?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(site.name)
                    .font(.headline)
                Text(site.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let hours = site.hours {
                    Text(hours)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if let distance {
                Text(distance, format: .measurement(width: .abbreviated, usage: .road))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DropOffSiteSheet: View {
    static let specialWasteGuide = URL(string: "https://www.nyc.gov/site/dsny/what-we-do/programs/special-waste-drop-off.page")

    let site: DropOffSite
    let distance: Measurement<UnitLength>?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Address", value: site.address)
                    if let borough = site.borough {
                        LabeledContent("Borough", value: borough)
                    }
                    if let hours = site.hours {
                        LabeledContent("Hours", value: hours)
                    } else if site.kind == .specialWaste {
                        LabeledContent("Hours", value: String(localized: "Tue–Sat, 9 AM–3 PM (closed legal holidays)"))
                    }
                    if let notes = site.notes {
                        Text(notes)
                            .font(.subheadline)
                    }
                    if let website = site.website {
                        Link("Website", destination: website)
                    }
                }

                if site.kind == .specialWaste, let guide = Self.specialWasteGuide {
                    Section {
                        Link("What You Can Bring", destination: guide)
                    } footer: {
                        Text("Batteries, paint, motor oil, fluorescent bulbs, e-waste and more. Some sites aren't visible from the road.")
                    }
                }
            }
            .navigationTitle(site.name)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: openDirections) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding()
            }
        }
    }

    private func openDirections() {
        let item = MKMapItem(location: site.location, address: MKAddress(fullAddress: site.address, shortAddress: nil))
        item.name = site.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }
}

extension DropOffSite.Kind {
    /// Tint used for the map markers and filter chips.
    var color: Color {
        switch self {
        case .specialWaste: .red
        case .electronics: .indigo
        case .foodScraps: .brown
        }
    }
}

#Preview {
    DropOffsView()
}
