//
//  GarbageCollectionStateModel.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/14/23.
//

import SwiftUI
import Collections

class GarbageCollectionStateModel: ObservableObject {
    @Published var garbage: OrderedDictionary = ["Monday": false, "Tuesday" : false, "Wednesday" : false, "Thursday": false, "Friday": false, "Saturday": false]
    @Published var largeItems: OrderedDictionary = ["Monday": false, "Tuesday" : false, "Wednesday" : false, "Thursday": false, "Friday": false, "Saturday": false]
    @Published var recycling: OrderedDictionary = ["Monday": false, "Tuesday" : false, "Wednesday" : false, "Thursday": false, "Friday": false, "Saturday": false]
    @Published var composting: OrderedDictionary = ["Monday": false, "Tuesday" : false, "Wednesday" : false, "Thursday": false, "Friday": false, "Saturday": false]
    
    @Published var textString = ""
    
    @Published var garbageData: Garbage?

    func sortData() {
        garbage = organizeCollection(from: garbageData?.regularCollectionSchedule, dictionary: &garbage)
        largeItems = organizeCollection(from: garbageData?.bulkPickupCollectionSchedule, dictionary: &largeItems)
        recycling = organizeCollection(from: garbageData?.recyclingCollectionSchedule, dictionary: &recycling)
        composting = organizeCollection(from: garbageData?.organicsCollectionSchedule, dictionary: &composting)
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
}
