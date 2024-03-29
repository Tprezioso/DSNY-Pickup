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
    @Published var isLoading = false
    @Published var alertItem: AlertItem?
    
    @Published var searchString = ""
    @Published var stringViewString = ""
    @Published var isAddFavoritesEnabled: Bool = false
    
    @Published var garbageData: Garbage?
    @Published var places = [PlaceViewModel]()
    

    func getGarbageCollectionData() {
        Task { @MainActor in
            isLoading = true
            do {                
                garbageData = try await NetworkManager.shared.getGarbageDetails(atAddress: searchString)
                stringViewString = garbageData?.formattedAddress ?? ""
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
    
    func saveGarbageCollectionData(newGarbageCollection: GarbageCollection) {
        newGarbageCollection.id = UUID()
        newGarbageCollection.formattedAddress = garbageData?.formattedAddress
        newGarbageCollection.bulkPickupCollectionSchedule = garbageData?.bulkPickupCollectionSchedule
        newGarbageCollection.organicsCollectionSchedule = garbageData?.organicsCollectionSchedule
        newGarbageCollection.regularCollectionSchedule = garbageData?.regularCollectionSchedule
        newGarbageCollection.recyclingCollectionSchedule = garbageData?.recyclingCollectionSchedule
        newGarbageCollection.commercialRoutingTime = garbageData?.routingTime?.commercialRoutingTime
        newGarbageCollection.residentialRoutingTime = garbageData?.routingTime?.residentialRoutingTime
        newGarbageCollection.mixedUseRoutingTime = garbageData?.routingTime?.mixedUseRoutingTime
        newGarbageCollection.additionalLinks = garbageData?.routingTime?.additionalLinks
        newGarbageCollection.frequencyOfDays = DayOf.dayOf.description
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
