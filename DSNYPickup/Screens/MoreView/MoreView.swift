//
//  MoreView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/30/23.
//

import SwiftUI

struct MoreView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        List {
            NavigationLink("Collection Information") {
                CollectionInfo()
            }
            
            Link(destination: URL(string: "https://www1.nyc.gov/assets/dsny/site/our-work/zero-waste")!) {
                Text("Zero Waste to Landfills")
            }
            
            Link(destination: URL(string: "https://portal.311.nyc.gov")!) {
                Text("Report Missed Collection")
            }
            
            Link(destination: URL(string: "https://portal.311.nyc.gov")!) {
                Text("Report Graffiti")
            }
            
            NavigationLink("Special Waste Drop-Off Locations") {
                Text("alskdjfhlakjsfh")
                    .onTapGesture {
                        locationManager.openMapWithAddress(location: BoroDropOffAddress.bronx)
                    }
            }
        }.navigationTitle("More")
    }
}

struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView()
    }
}

enum BoroDropOffAddress {
   static let brooklyn = "459 N Henry St, Brooklyn, NY 11222"
   static let bronx = "800 Food Center Drive, The Bronx, NY 10474"
   static let queens = "120-15 31st Ave Flushing, NY 11354"
   static let manhattan = "74 Pike Slip, New York, NY 10002"
   static let statanIsland = "1323 W Service Rd Staten Island, NY 10309"
}
