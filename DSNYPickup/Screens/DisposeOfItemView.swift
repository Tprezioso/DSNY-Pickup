//
//  DisposeOfItemView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/25/23.
//

import SwiftUI

struct DisposeOfItemView: View {
    @StateObject var viewModel = DisposeOfItemViewModel()
    @State var test = ""
    var body: some View {
        
        Text(LocalizedStringKey(viewModel.itemsToDisposeData?.first?.excerpt ?? "WTFFF"))
        .onAppear {
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
    
    func getItemDisposalDetails() {
        Task { @MainActor in
            isLoading = true
            do {
                itemsToDisposeData = try await NetworkManager.shared.getItemDisposalDetails(for: "auto batteries")
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
    }
}
