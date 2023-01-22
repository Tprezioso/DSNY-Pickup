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
                                .scaledToFit()
                                .minimumScaleFactor(0.4)
                        }.foregroundColor(.green)
                            .padding(4)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10.0)
                                    .stroke(.green)
                            }
                    } else {
                        Text("")
                            .frame(width: 40, height: 60)
                    }
                }
            }
            Divider()
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
                                .scaledToFit()
                                .minimumScaleFactor(0.6)
                        }.foregroundColor(.green)
                            .padding(4)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10.0)
                                    .stroke(.green)
                            }
                        
                        
                    } else {
                        Text("")
                            .frame(width: 40, height: 60)
                    }
                }
            }
            Divider()
            
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
                                .scaledToFit()
                                .minimumScaleFactor(0.4)
                        }.foregroundColor(.cyan)
                            .padding(4)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10.0)
                                    .stroke(.cyan)
                            }
                        
                    } else {
                        Text("")
                            .frame(width: 40, height: 60)
                    }
                }
            }
            Divider()
            
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
                                .scaledToFit()
                                .minimumScaleFactor(0.4)
                        }
                        .foregroundColor(.orange)
                        .padding(4)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(.orange)
                        }
                    } else {
                        Text("")
                            .frame(width: 40, height: 60)
                    }
                }
            }
            Divider()            
        }.padding(.all, 10)
    }
}
