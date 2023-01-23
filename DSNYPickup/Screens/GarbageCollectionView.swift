//
//  ContentView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import SwiftUI

struct GarbageCollectionView: View {
    @StateObject var viewModel = GarbageCollectionStateModel()
    @StateObject private var locationManager = LocationManager()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.isSearching) private var isSearching
    
    init() {
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("\(viewModel.stringViewString)")
                        .font(.title)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    GarbageCollectionGridView(
                        garbage: viewModel.garbage,
                        largeItems: viewModel.largeItems,
                        recycling: viewModel.recycling,
                        composting: viewModel.composting
                    )
                    
                    Button {
                        // TODO: - Need to add Core Data to save address
                        print("Saved")
                    } label: {
                        Label("Add to Favorites", systemImage: "star")
                            .bold()
                    }
                    .padding(.horizontal)
                    .buttonStyle(RoundedRectangleButtonStyle())
                    
                    Spacer()
                }.onAppear {
                    viewModel.getGarbageCollectionData()
                }
                .searchable(text: $viewModel.searchString, placement: .navigationBarDrawer(displayMode: .always), prompt: viewModel.searchString.isEmpty ? "When is Collection at..." : viewModel.searchString) {
                    ForEach(viewModel.places) { place in
                        SearchView(place: place.name, viewModel: viewModel)
                    }
                }
                .onSubmit(of: .search) {
                    viewModel.getGarbageCollectionData()
                }
                .onChange (of: viewModel.searchString, perform: { searchText in
                    viewModel.search(text: searchText, region: locationManager.region)
                })
            }.navigationTitle("DSNY Garbage Collection")
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(Color.accentColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            if viewModel.isLoading {
                ProgressView()
            }
        }.alert(item: $viewModel.alertItem) { alertItem in
            Alert.init(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
        }
        .onTapGesture {
            dismissKeyboardOnTap()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GarbageCollectionView()
    }
}

enum EnumDays: Int, CustomStringConvertible {
    var description: String {
        switch self {
        case .MONDAY:
            return "Monday"
        case .TUESDAY:
            return "Tuesday"
        case .WEDNESDAY:
            return "Wednesday"
        case .THURSDAY:
            return "Thursday"
        case .FRIDAY:
            return "Friday"
        case .SATURDAY:
            return "Saturday"
        case .SUNDAY:
            return "Sunday"
        }
    }
    case MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY
}

extension View {
  func dismissKeyboardOnTap() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
  }
}

struct RoundedRectangleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
      HStack {
            Spacer()
            configuration.label.foregroundColor(.white)
            Spacer()
          }
          .padding()
          .background(Color.accentColor.cornerRadius(8))
          .scaleEffect(configuration.isPressed ? 0.95 : 1)
  }
}

struct AddressSearchView: View {
    @StateObject var viewModel: GarbageCollectionStateModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search...", text: $viewModel.searchString, prompt: Text("When is collecting at..."))
                Button {
                    print("Save")
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .foregroundColor(.accentColor)
                        .frame(width: 30, height: 30)
                }
                
            }
            .font(.title2)
            .textFieldStyle(.roundedBorder)
            .submitLabel(.search)
            .onSubmit {
                viewModel.getGarbageCollectionData()
            }
        }.padding()
    }
}

struct SearchView: View {
    var place: String
    @StateObject var viewModel: GarbageCollectionStateModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSearch) private var dismissSearch
    
    var body: some View {
        Text(place)
            .onTapGesture {
                Task { @MainActor in
                    viewModel.searchString = place
                    viewModel.getGarbageCollectionData()
                }
                dismissSearch()
            }
    }
}
