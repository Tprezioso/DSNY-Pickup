//
//  GarbageCollectionGridView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/14/23.
//

import SwiftUI
import OrderedCollections

struct GarbageCollectionGridView: View {
    var garbage: OrderedDictionary<String, Bool>
    var largeItems: OrderedDictionary<String, Bool>
    var recycling: OrderedDictionary<String, Bool>
    var composting: OrderedDictionary<String, Bool>

    var body: some View {
            Grid {
            GridRow { CalendarHeaderView() }
            
            // Garbage
            GridRow {
                ForEach(garbage.values, id: \.self) { day in
                    if day == true {
                        VStack {
                            Image(systemName: "trash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                            
                            Text("Garbage")
                                .font(.caption)
                        }.foregroundColor(.green)
                    } else {
                        Text("")
                    }
                }
            }
            
            // Large Items
            GridRow {
                ForEach(largeItems.values, id: \.self) { day in
                    if day == true {
                        VStack {
                            Image(systemName: "sofa")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                            
                            Text("Large Items")
                                .font(.caption)
                        }.foregroundColor(.green)
                        
                    } else {
                        Text("")
                    }
                }
            }
            
            // Recycling
            GridRow {
                ForEach(recycling.values, id: \.self) { day in
                    if day == true {
                        VStack {
                            Image(systemName: "arrow.3.trianglepath")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                            
                            Text("Recycling")
                                .font(.caption)
                        }.foregroundColor(.cyan)
                    } else {
                        Text("")
                    }
                }
            }
            
            // Composting
            GridRow {
                ForEach(composting.values, id: \.self) { day in
                    if day == true {
                        VStack {
                            Image(systemName: "leaf.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                            
                            Text("Compost")
                                .font(.caption)
                                .minimumScaleFactor(0.4)
                        }
                        .foregroundColor(.orange)
                    } else {
                        Text("")
                    }
                }
            }
        }
    }
}
