//
//  ContentView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import SwiftUI

struct GarbagePickupDays: View {
    var body: some View {
        VStack {
            Text("SearchView")
                .padding()
            Text("InfoView")
        }.onAppear {
            NetworkManager.shared.getData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GarbagePickupDays()
    }
}
