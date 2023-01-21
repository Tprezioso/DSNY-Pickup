//
//  GarbageCollectionStateModel.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/14/23.
//

import SwiftUI
import Collections

class GarbageCollectionStateModel: ObservableObject {
    @Published var garbage: OrderedDictionary = WeekDay.week
    @Published var largeItems: OrderedDictionary = WeekDay.week
    @Published var recycling: OrderedDictionary = WeekDay.week
    @Published var composting: OrderedDictionary = WeekDay.week
    @Published var isLoading = false
    @Published var alertItem: AlertItem?
    
    @Published var searchString = "12 Jamaica ave"
    
    @Published var garbageData: Garbage?

    func getGarbageCollectionData() {
        Task { @MainActor in
            isLoading = true
            do {
                garbageData = try await NetworkManager.shared.getGarbageDetails(atAddress: searchString)
                sortData()
                isLoading = false
            } catch {
                print("❌ Error getting garbage data")
                switch error {
                case NetworkError.invalidData:
                    self.alertItem = AlertContext.invalidData
                    
                case NetworkError.invalidURL:
                    self.alertItem = AlertContext.invalidURL
                    
                case NetworkError.invalidResponse:
                    self.alertItem = AlertContext.invalidResponse
                default:
                    self.alertItem = AlertContext.unableToComplete
                }
                isLoading = false
            }
        }
    }
    
    func sortData() {
        resetArrayData()
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
