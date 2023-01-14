//
//  ContentView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import SwiftUI

struct GarbagePickupDays: View {
    let tempURL = "https://data.cityofnewyork.us/resource/rv63-53db.json?$where=within_circle(multipolygon,%2040.60682780600007,%20-74.00173702999996,%201000)"

    var body: some View {
        VStack {
            Text("SearchView")
                .padding()
            Text("InfoView")
        }.onAppear {
            Task { @MainActor in
                try await NetworkManager.shared.getGarbageDetails(atUrl: tempURL)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GarbagePickupDays()
    }
}
