import SwiftUI

struct RootView: View {
    enum Section: Hashable {
        case home, getRidOf, dropOffs, more
    }

    @Environment(AppNavigator.self) private var navigator
    @SceneStorage("selectedTab") private var savedSelection: Section = .home

    var body: some View {
        @Bindable var navigator = navigator
        TabView(selection: $navigator.selectedTab) {
            Tab("Pickups", systemImage: "calendar", value: .home) {
                HomeView()
            }
            Tab("Get Rid Of", systemImage: "arrow.3.trianglepath", value: .getRidOf) {
                GetRidOfView()
            }
            Tab("Drop-Offs", systemImage: "mappin.and.ellipse", value: .dropOffs) {
                DropOffsView()
            }
            Tab("More", systemImage: "ellipsis.circle", value: .more) {
                MoreView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(isPresented: $navigator.showsPaywall) {
            ProPaywallView()
        }
        .onAppear { navigator.selectedTab = savedSelection }
        .onChange(of: navigator.selectedTab) { savedSelection = $1 }
    }
}

extension RootView.Section: RawRepresentable {
    init?(rawValue: String) {
        switch rawValue {
        case "home": self = .home
        case "getRidOf": self = .getRidOf
        case "dropOffs": self = .dropOffs
        case "more": self = .more
        default: return nil
        }
    }

    var rawValue: String {
        switch self {
        case .home: "home"
        case .getRidOf: "getRidOf"
        case .dropOffs: "dropOffs"
        case .more: "more"
        }
    }
}

#Preview {
    RootView()
        .environment(AddressStore.preview)
        .environment(AppNavigator(store: AddressStore.preview))
        .environment(PurchaseManager())
        .modelContainer(AddressStore.preview.context.container)
}
