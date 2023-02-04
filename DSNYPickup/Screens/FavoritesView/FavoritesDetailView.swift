//
//  FavoritesDetailView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/2/23.
//

import SwiftUI
import Collections

struct FavoritesDetailView: View {
    var garbageCollection: GarbageCollection
    @State var garbage: OrderedDictionary = WeekDay.week
    @State var largeItems: OrderedDictionary = WeekDay.week
    @State var recycling: OrderedDictionary = WeekDay.week
    @State var composting: OrderedDictionary = WeekDay.week
    @State var isLoading = false
    
    var body: some View {
        ScrollView {
            Text(garbageCollection.formattedAddress ?? "")
                .font(.title)
            GarbageCollectionGridView(
                garbage: garbage,
                largeItems: largeItems,
                recycling: recycling,
                composting: composting
            )
            Spacer()
        }.padding()
        .navigationTitle("Collection Details")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.accentColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            sortData()
        }
    }
    
     func sortData() {
        resetArrayData()
        garbage = organizeCollection(from: garbageCollection.regularCollectionSchedule, dictionary: &garbage)
        largeItems = organizeCollection(from: garbageCollection.bulkPickupCollectionSchedule, dictionary: &largeItems)
        recycling = organizeCollection(from: garbageCollection.recyclingCollectionSchedule, dictionary: &recycling)
        composting = organizeCollection(from: garbageCollection.organicsCollectionSchedule, dictionary: &composting)
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

//struct FavoritesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        FavoritesDetailView(garbageCollection: .init())
//    }
//}
