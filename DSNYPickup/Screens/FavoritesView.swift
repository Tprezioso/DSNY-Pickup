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
//        NavigationView {
                    List {
                        if garbageCollectionItems.isEmpty {
                            Text("No Favorites found")
                        }
                        ForEach(garbageCollectionItems) { item in
                            Text(item.formattedAddress ?? "No Name")
                                .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                                .onTapGesture {
//                                    item.isCompleted = !item.isCompleted
                                    /// -> remove this line manager.objectWillChange.send()
                                }
                        }
                    }.navigationTitle("Favorites")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
//                    .navigationTitle("Favorites")
//                    .navigationBarItems(trailing: Button(action: addItem, label: {
//                        Image(systemName: "plus")
//                    }))
//                }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
