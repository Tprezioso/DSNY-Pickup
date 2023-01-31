//
//  MoreView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/30/23.
//

import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            NavigationLink("Collection Information") {
                CollectionInfo()
            }
        }
    }
}

struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView()
    }
}
