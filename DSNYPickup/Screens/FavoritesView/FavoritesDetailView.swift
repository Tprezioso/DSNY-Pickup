//
//  FavoritesDetailView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/2/23.
//

import SwiftUI
import Collections

struct FavoritesDetailView: View {
    var garbageCollection: GarbageCollection
    
    @State var isLoading = false
    
    var body: some View {
        ScrollView {
            Text(garbageCollection.formattedAddress ?? "")
                .font(.title)
            GarbageCollectionGridView(
                garbageCollection: garbageCollection
            )
            Spacer()
        }.padding()
        .navigationTitle("Collection Details")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.accentColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }    
}

//struct FavoritesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        FavoritesDetailView(garbageCollection: .init())
//    }
//}
