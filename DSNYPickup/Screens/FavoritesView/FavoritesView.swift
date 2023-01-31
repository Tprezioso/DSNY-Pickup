//
//  FavoritesView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/29/23.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var manager: DataManager
        @Environment(\.managedObjectContext) private var viewContext
        @FetchRequest(sortDescriptors: []) private var garbageCollectionItems: FetchedResults<GarbageCollection>
    
    var body: some View {
        List {
            if garbageCollectionItems.isEmpty {
                Text("No Favorites found")
            }
            ForEach(garbageCollectionItems) { item in
                Text(item.formattedAddress ?? "No Name")
                    .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                    .onTapGesture {
                    }
            }.onDelete(perform: removeFavorite)
        }.navigationTitle("Favorites")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
    
    func removeFavorite(at offsets: IndexSet) {
        for index in offsets {
            let garbageCollectionItem = garbageCollectionItems[index]
            viewContext.delete(garbageCollectionItem)
            do {
                try viewContext.save()
            } catch {
                print("save error")
            }
        }
    }
    
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}

class FavoritesStateModelView: ObservableObject {
    
    
}
