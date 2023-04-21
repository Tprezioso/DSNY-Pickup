//
//  GarbageCollectionGridView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/14/23.
//

import SwiftUI
import OrderedCollections

struct GarbageCollectionGridView: View {
    var garbageData: Garbage?
    var garbageCollection: GarbageCollection?
    var isWidget: Bool
    @State var garbages: Garbage?
    @State var garbage: OrderedDictionary = WeekDay.week
    @State var largeItems: OrderedDictionary = WeekDay.week
    @State var recycling: OrderedDictionary = WeekDay.week
    @State var composting: OrderedDictionary = WeekDay.week
    
    init(garbageData: Garbage? = nil, garbageCollection: GarbageCollection? = nil, isWidget: Bool = false) {
        self.garbageData = garbageData
        self.garbageCollection = garbageCollection
        self.isWidget = isWidget
    }
    
    var body: some View {
        Grid {
            GridRow { CalendarHeaderView(isWidget: isWidget) }
            
            // Garbage
            GridRow {
                ForEach(garbage.values, id: \.self) { day in
                    if day == true {
                        VStack {
                            Image(systemName: "trash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isWidget ? 15 : 30 , height: isWidget ? 15 : 30)
                            if !isWidget {
                                Text("Garbage")
                                    .font(.caption)
                                    .scaledToFit()
                                .minimumScaleFactor(0.4)
                            }
                        }.foregroundColor(.green)
//                            .padding(4)
//                            .overlay {
//                                RoundedRectangle(cornerRadius: 10.0)
//                                    .stroke(.green)
//                            }
                    } else {
                        Text("")
                            .frame(width: isWidget ? 15 : 40, height: isWidget ? 15 : 60)
                    }
                }
            }
            Divider()
            // Large Items
            GridRow {
                ForEach(largeItems.values, id: \.self) { day in
                    if day == true {
                        VStack(spacing: 0) {
                            Image(systemName: "sofa")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isWidget ? 15 : 40 , height: isWidget ? 15 : 40)
                            if !isWidget {
                                Text("Large Items")
                                    .font(.caption2)
                                    .scaledToFit()
                                    .minimumScaleFactor(0.6)
                            }
                        }.foregroundColor(.green)
//                            .padding(4)
//                            .overlay {
//                                RoundedRectangle(cornerRadius: 10.0)
//                                    .stroke(.green)
//                            }
                        
                        
                    } else {
                        Text("")
                            .frame(width: isWidget ? 15 : 40, height: isWidget ? 15 : 60)
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
                                .frame(width: isWidget ? 15 : 30 , height: isWidget ? 15 : 30)
                            if !isWidget {
                                Text("Recycling")
                                    .font(.caption)
                                    .scaledToFit()
                                .minimumScaleFactor(0.4)
                            }
                        }.foregroundColor(.cyan)
//                            .padding(4)
//                            .overlay {
//                                RoundedRectangle(cornerRadius: 10.0)
//                                    .stroke(.cyan)
//                            }
                        
                    } else {
                        Text("")
                            .frame(width: isWidget ? 15 : 40, height: isWidget ? 15 : 60)
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
                                .frame(width: isWidget ? 20 : 30, height: isWidget ? 20 : 30)
                            if !isWidget {
                                Text("Compost")
                                    .font(.caption)
                                    .scaledToFit()
                                    .minimumScaleFactor(0.4)
                            }
                        }
                        .foregroundColor(.orange)
//                        .padding(4)
//                        .overlay {
//                            RoundedRectangle(cornerRadius: 10.0)
//                                .stroke(.orange)
//                        }
                    } else {
                        Text("")
                            .frame(width: isWidget ? 20 : 40, height: isWidget ? 20 : 60)
                    }
                }
            }
            Divider()            
        }.padding(10)
            .onAppear {
                sortData()
            }
            .onChange(of: garbageData) { newValue in
                garbages = newValue
                sortData()
            }
    }
    
    func sortData() {
        resetArrayData()
        
        if garbages?.formattedAddress != nil {
            garbage = organizeCollection(from: garbages?.regularCollectionSchedule, dictionary: &garbage)
            largeItems = organizeCollection(from: garbages?.bulkPickupCollectionSchedule, dictionary: &largeItems)
            recycling = organizeCollection(from: garbages?.recyclingCollectionSchedule, dictionary: &recycling)
            composting = organizeCollection(from: garbages?.organicsCollectionSchedule, dictionary: &composting)
        } else if garbageCollection != nil {
            garbage = organizeCollection(from: garbageCollection?.regularCollectionSchedule, dictionary: &garbage)
            largeItems = organizeCollection(from: garbageCollection?.bulkPickupCollectionSchedule, dictionary: &largeItems)
            recycling = organizeCollection(from: garbageCollection?.recyclingCollectionSchedule, dictionary: &recycling)
            composting = organizeCollection(from: garbageCollection?.organicsCollectionSchedule, dictionary: &composting)
        }
    }

   func organizeCollection(from schedule: String?, dictionary: inout OrderedDictionary<String, Bool>) -> OrderedDictionary<String, Bool> {
       if let regularCollection = schedule {
           let splitArray = regularCollection.split(separator: ",")
           for pick in splitArray {
               for day in dictionary.keys.sorted() {
                   if pick == day {
                       dictionary[day] = true
                   }
               }
           }

       }
       return dictionary
   }

    func resetArrayData() {
       garbage.forEach({ (key, value) -> Void in
           garbage[key] = false
       })
       largeItems.forEach({ (key, value) -> Void in
           largeItems[key] = false
       })
       recycling.forEach({ (key, value) -> Void in
           recycling[key] = false
       })
       composting.forEach({ (key, value) -> Void in
           composting[key] = false
       })
   }

}
