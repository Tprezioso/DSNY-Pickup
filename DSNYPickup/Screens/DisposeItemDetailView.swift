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
            Text(stateModel.parseHTMLStringFromData(string: stateModel.itemToDispose.excerpt ?? ""))
            
            Link("More Information", destination: (URL(string: stateModel.parseForURL(string: stateModel.itemToDispose.excerpt ?? NetworkManager.baseURL)) ?? URL(string: NetworkManager.baseURL))!)
                .buttonStyle(RoundedRectangleButtonStyle())
                .padding(.horizontal)
        }
        .navigationTitle(stateModel.itemToDispose.name?.capitalized.replacingOccurrences(of: "-", with: " ") ?? "")
    }
}

//struct DisposeItemDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        DisposeItemDetailView(itemToDispose: MockData.detailSearchItemToDispose)
//    }
//}

class DisposeItemDetailStateModel: ObservableObject {
    @State var itemToDispose: ItemToDispose
//    @Published var buttons: String
    
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
    func parseForURL(string: String) -> String {
        
        do {
            let html: String = "<p>\(string)</p>"
            let doc: Document = try SwiftSoup.parse(html)
            let link: Element? = try doc.select("a").first()
            if let link = link {
                let linkHref: String = try link.attr("href") // "http://example.com/"
                let linkText: String = try link.text() // "example"
                
                let linkOuterH: String = try link.outerHtml() // "<a href="http://example.com/"><b>example</b></a>"
                let linkInnerH: String = try link.html() // "<b>example</b>"
                //                 = linkHref
                return linkHref
            }
            
           
        } catch Exception.Error(let type, let message) {
            print(message)
            return message
        } catch {
            print("error")
            return ""
        }
        return ""
    }
}
