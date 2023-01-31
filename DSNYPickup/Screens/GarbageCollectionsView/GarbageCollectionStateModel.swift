//
//  GarbageCollectionStateModel.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/14/23.
//

import SwiftUI
import Collections
import MapKit

@MainActor
class GarbageCollectionStateModel: ObservableObject {
    @Published var garbage: OrderedDictionary = WeekDay.week
    @Published var largeItems: OrderedDictionary = WeekDay.week
    @Published var recycling: OrderedDictionary = WeekDay.week
    @Published var composting: OrderedDictionary = WeekDay.week
    @Published var isLoading = false
    @Published var alertItem: AlertItem?
    
    @Published var searchString = ""
    @Published var stringViewString = ""
    
    @Published var garbageData: Garbage?
    @Published var places = [PlaceViewModel]()
    

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
        stringViewString = garbageData?.formattedAddress ?? ""
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
    
    func search(text: String, region: MKCoordinateRegion) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = text
        searchRequest.region = region
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response else {
                print ("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.places = response.mapItems.map(PlaceViewModel.init)
        }
    }
}
