//
//  DisposeItemDetailView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/27/23.
//

import SwiftUI
import SwiftSoup

struct DisposeItemDetailView: View {
    @StateObject var stateModel: DisposeItemDetailStateModel

    var body: some View {
        VStack {
            ScrollView {
                Text(stateModel.parseHTMLStringFromData(string: stateModel.itemToDispose.excerpt ?? ""))
                    .font(.title3)
            }
            Spacer()
            ForEach(stateModel.buttons) { button in
                Link(button.name.capitalized, destination: (URL(string: button.url) ?? URL(string: NetworkManager.baseURL))!)
                    .buttonStyle(RoundedRectangleButtonStyle())
            }
        }.padding()
        .onAppear {
            stateModel.parseForURL(string: stateModel.itemToDispose.excerpt ?? "")
        }
        .navigationTitle(stateModel.itemToDispose.name?.capitalized.replacingOccurrences(of: "-", with: " ") ?? "")
    }
}

struct DisposeItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DisposeItemDetailView(stateModel: DisposeItemDetailStateModel(itemToDispose: MockData.detailSearchItemToDispose))
    }
}

class DisposeItemDetailStateModel: ObservableObject {
    @State var itemToDispose: ItemToDispose
    @Published var buttons = [DetailItemButton]()
    
    init(itemToDispose: ItemToDispose) {
        self.itemToDispose = itemToDispose
    }
    
    func parseHTMLStringFromData(string: String) -> String {
        do {
            let html: String = "<p>\(string)</p>"
            let doc: Document = try SwiftSoup.parse(html)
            let text: String = try doc.body()!.text() // "An example link."
            
            return text
        } catch Exception.Error(_, let message) {
            print(message)
            return message
        } catch {
            print("error")
            return ""
        }
        
    }
    
    // TODO: - make buttons model and iterate over for options depending on description
    func parseForURL(string: String) {
        
        do {
            let html: String = "<p>\(string)</p>"
            let doc: Document = try SwiftSoup.parse(html)
            let links: Elements? = try doc.select("a")
            if let links {
                for link in links {
                    let linkHref: String = try link.attr("href") // "http://example.com/"
                    let linkText: String = try link.text() // "example"
                    
                    let linkOuterH: String = try link.outerHtml() // "<a href="http://example.com/"><b>example</b></a>"
                    let linkInnerH: String = try link.html() // "<b>example</b>"
                    var button = DetailItemButton(name: linkText, url: linkHref)
                    self.buttons.append(button)
                }
            }
        } catch Exception.Error(let type, let message) {
            print(message)
        } catch {
            print("error")
        }
        
        if self.buttons.isEmpty {
            self.buttons.append(DetailItemButton(name: "More Information", url: NetworkManager.baseURL))
        }
        
    }
}
