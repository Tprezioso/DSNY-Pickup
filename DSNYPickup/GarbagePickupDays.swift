//
//  ContentView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/4/21.
//

import SwiftUI

struct GarbagePickupDays: View {
    let tempURL = "https://data.cityofnewyork.us/resource/rv63-53db.json?$where=within_circle(multipolygon,%2040.73623017912892,%20-73.80868539963596,%201000)"

    let collectionURL = "https://a827-donatenyc.nyc.gov/DSNYGeoCoder/api/DSNYCollection/CollectionSchedule?address=6525%20160th%20Street%2C%20Fresh%20Meadows%2C%20NY%2C%20USA"
    
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
