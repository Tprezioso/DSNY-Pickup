//
//  DisposeOfItemView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/25/23.
//

import SwiftUI

struct DisposeOfItemView: View {
    @StateObject var viewModel = DisposeOfItemViewModel()
    var body: some View {
        Text("Hello")
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
    @Published var garbageData: ItemsToDispose?
    
    func getItemDisposalDetails() {
        Task { @MainActor in
            isLoading = true
            do {
                garbageData = try await NetworkManager.shared.getItemDisposalDetails(for: "asdf")
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
