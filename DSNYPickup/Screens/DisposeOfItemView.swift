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
        //Use this if NavigationBarTitle is with Large Font
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(.accentColor)]
    }
    
    var body: some View {
            List {
                ForEach(viewModel.itemsToDisposeData ?? []) { itemToDispose in
                    NavigationLink(itemToDispose.name ?? "") {
                        Text(itemToDispose.name ?? "")
                    }
                }
                
            }.searchable(text: $viewModel.searchText)
            .onSubmit(of: .search) { 
                    print("submit")
                viewModel.getItemDisposalDetails()
            }
            .navigationTitle("How to Get Rid of ...")
        
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
    @Published var searchText = ""
    
    func getItemDisposalDetails() {
        Task { @MainActor in
            isLoading = true
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
    }
    
    func parseHTMLStringFromData(string: String) -> String {
        do {
            let html: String = "<p>\(string)</p>"
            let doc: Document = try SwiftSoup.parse(html)
            let link: Element = try doc.select("a").first()!
            
            let text: String = try doc.body()!.text() // "An example link."
            let linkHref: String = try link.attr("href") // "http://example.com/"
            let linkText: String = try link.text() // "example"
            
            let linkOuterH: String = try link.outerHtml() // "<a href="http://example.com/"><b>example</b></a>"
            let linkInnerH: String = try link.html() // "<b>example</b>"
            
            return text
        } catch Exception.Error(let type, let message) {
            print(message)
            return message
        } catch {
            print("error")
            return "Error"
        }
        
    }
}
