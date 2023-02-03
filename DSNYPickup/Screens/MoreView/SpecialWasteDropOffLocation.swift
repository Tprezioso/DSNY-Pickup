//
//  SpecialWasteDropOffLocation.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/2/23.
//

import SwiftUI

struct SpecialWasteDropOffLocation: View {
    
    
    var body: some View {
        List {
            Text(
                """
Special Waste Drop-Off Sites are locations where New York City residents can drop-off certain harmful products. The sites are open from 10 AM to 5 PM every Saturday and the last Friday of the month. Sites are closed on legal holidays and may be closed during severe weather.
""")
            ForEach(BoroDropOffAddress.allCases, id: \.self) { boro in
                BoroDirectionsButtonView(boro: boro)
            }
            
            Section("What to bring") {
                Text("The following items are accepted at DSNY Special Waste Drop-Off Sites:")
                Text(
                    """
    • Batteries, including automotive, rechargeable (such as small sealed lead acid batteries, Li-Ion, Ni-MH, Ni-ZN, Ni-Cd) and single-use (such as alkaline and lithium primary). Follow instructions below to prepare batteries before arrival.
    
    • Motor oil and transmission fluid (up to 10 quarts per visit)
    
    • Motor oil filters (up to two filters per visit)
    
    • Fluorescent light bulbs & CFLs
    
    • Latex paint (up to five gallons per visit)
    
    • Mercury-containing devices (up to two per visit)
    
    • Passenger car tires (up to four per visit)
    
    • Electronics (covered by the NYS disposal ban)
    """)
                Link(destination: URL(string: "https://dsny.cityofnewyork.us/wp-content/uploads/2021/06/Special-Waste_How-To-Dispose-Flyer-june21.pdf")!) {
                    Text("Download Our Checklist")
                }
            }
        }.navigationTitle("Special Waste Drop-Off Location")
    }
}

struct SpecialWasteDropOffLocation_Previews: PreviewProvider {
    static var previews: some View {
        SpecialWasteDropOffLocation()
    }
}

struct BoroDirectionsButtonView: View {
    @StateObject private var locationManager = LocationManager()
    
    var boro: BoroDropOffAddress
    var body: some View {
        Section(header: Text(boro.name)) {
            Button {
                locationManager.openMapWithAddress(location: boro.address)
            } label: {
                Text("\(boro.name) Drop Off Directions")
            }
        }
    }
}
