//
//  DisposeItemDetailView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/27/23.
//

import SwiftUI

struct DisposeItemDetailView: View {
    @State var itemToDispose: ItemToDispose
    
    var body: some View {
        VStack {
            Text(itemToDispose.excerpt ?? "")
//            Button {
//
//            } label: {
//                Text("More Information")
//
//            }
            if let linkedPage = itemToDispose.linkedPage {
             let _ = print(">>>\(linkedPage)")
//                Link("More Information", destination: URL(string: $itemToDispose.)!)
//                    .buttonStyle(RoundedRectangleButtonStyle())
//                    .padding(.horizontal)
            }

        }
        .navigationTitle(itemToDispose.name?.capitalized.replacingOccurrences(of: "-", with: " ") ?? "")
    }
}

//struct DisposeItemDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        DisposeItemDetailView(itemToDispose: MockData.detailSearchItemToDispose)
//    }
//}
