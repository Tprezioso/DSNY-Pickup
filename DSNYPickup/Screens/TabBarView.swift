//
//  TabBarView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/20/23.
//

import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            NavigationStack {
                GarbageCollectionView()
            }.tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)
            
            NavigationStack {
                FavoritesView()
            }.tabItem {
                Label("Favorites", systemImage: "star")
            }.tag(2)
            
            NavigationStack {
                DisposeOfItemView()
            }.tabItem {
                Label("Trash", systemImage: "trash")
            }.tag(3)
            
            NavigationStack {
                EmptyView()
            }.tabItem {
                Label("More", systemImage: "ellipsis")
            }.tag(4)
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
