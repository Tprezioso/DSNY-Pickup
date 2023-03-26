//
//  DisposeOfItemView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/25/23.
//

import SwiftUI
import SwiftSoup

struct DisposeOfItemView: View {
    @StateObject var viewModel = DisposeOfItemViewModel()
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(.accentColor)]
    }
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.sortedItemsToDispose, id: \.key) { itemToDispose in
                    NavigationLink((itemToDispose.key).capitalized.replacingOccurrences(of: "-", with: " ")) {
                        DisposeItemDetailView(stateModel: DisposeItemDetailStateModel(itemToDispose: itemToDispose.value.first!))
                    }
                }
                
                
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }.searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: viewModel.searchText) { text in
            viewModel.getItemDisposalDetails()
            viewModel.sortedItemsToDispose = viewModel.sortedItemsToDispose.filter { $0.key.starts(with: text.capitalized) }
        }
        .onSubmit(of: .search) {
            viewModel.getItemDisposalDetails()
        }
        .navigationTitle("How to Get Rid of ...")
        .onAppear {
            viewModel.getItemDisposalDetails()
        }
        .refreshable {
            viewModel.getItemDisposalDetails()
        }
    }
}

struct DisposeOfItemView_Previews: PreviewProvider {
    static var previews: some View {
        DisposeOfItemView()
    }
}

@MainActor
class DisposeOfItemViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var alertItem: AlertItem?
    @Published var itemsToDisposeData: ItemsToDispose?
    @Published var searchText = ""
    @Published var sortedItemsToDispose = [Dictionary<String, ItemsToDispose>.Element]()
    
    func getItemDisposalDetails() {
        Task { @MainActor in
            isLoading = true
            await getItemsData()
            sortedItemsToDispose = sortNamesOfItemsIntoDictionary(items: itemsToDisposeData ?? ItemsToDispose())
        }
    }
    
    func getItemsData() async {
        do {
            itemsToDisposeData = try await NetworkManager.shared.getItemDisposalDetails(for: searchText)
            isLoading = false
        } catch {
            print("❌ Error getting garbage data")
            switch error {
            case NetworkError.invalidData:
                self.alertItem = AlertContext.invalidData
                
            case NetworkError.invalidURL:
                self.alertItem = AlertContext.invalidURL
                
            case NetworkError.invalidResponse:
                self.alertItem = AlertContext.invalidResponse
            default:
                self.alertItem = AlertContext.unableToComplete
            }
            isLoading = false
        }
    }
    
    func sortNamesOfItemsIntoDictionary(items: ItemsToDispose) -> [Dictionary<String, ItemsToDispose>.Element] {
        let groupByName = Dictionary(grouping: items) { (device) -> String in
            return device.name!
        }
        return groupByName.sorted{ $0.key < $1.key }
    }
}
