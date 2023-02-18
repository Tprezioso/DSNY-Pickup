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
    @StateObject var notificationManager = NotificationManager()
    
    var body: some View {
        List {
            if garbageCollectionItems.isEmpty {
                Text("No Favorites found")
            }
            ForEach(garbageCollectionItems) { item in
                NavigationLink {
                    FavoritesDetailView(stateModel: FavoritesDetailViewStateModel(garbageCollection: item), notificationManager: notificationManager)
                } label: {
                    Text(item.formattedAddress ?? "No Name")
                        .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }
            }.onDelete(perform: removeFavorite)
        }.navigationTitle("Favorites")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.accentColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .padding(.vertical)
    }
    
    func removeFavorite(at offsets: IndexSet) {
        for index in offsets {
            let garbageCollectionItem = garbageCollectionItems[index]
            notificationManager.removeNotificationWith(id: garbageCollectionItem.id?.uuidString ?? UUID().uuidString)
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
