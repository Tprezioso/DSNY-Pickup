//
//  PlaceView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/21/23.
//

import Foundation
import MapKit

struct PlaceViewModel: Identifiable {
    let id = UUID()
    private var mapItem: MKMapItem
    
    init (mapItem: MKMapItem) {
        self.mapItem = mapItem
    }
    
    var name: String {
        mapItem.name ?? ""
    }
}
