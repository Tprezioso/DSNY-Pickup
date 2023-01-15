//
//  GarbageCollection.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/13/23.
//


import Foundation

struct Garbage: Codable {
    let bulkPickupCollectionSchedule, regularCollectionSchedule, recyclingCollectionSchedule, organicsCollectionSchedule: String?
    let formattedAddress: String?

    init(bulkPickupCollectionSchedule: String? = "",
         regularCollectionSchedule: String? = "",
         recyclingCollectionSchedule: String? = "",
         organicsCollectionSchedule: String? = "",
         formattedAddress: String? = ""
    ) {
        self.bulkPickupCollectionSchedule = bulkPickupCollectionSchedule
        self.regularCollectionSchedule = regularCollectionSchedule
        self.recyclingCollectionSchedule = recyclingCollectionSchedule
        self.organicsCollectionSchedule = organicsCollectionSchedule
        self.formattedAddress = formattedAddress
    }
    
    enum CodingKeys: String, CodingKey {
        case bulkPickupCollectionSchedule = "BulkPickupCollectionSchedule"
        case regularCollectionSchedule = "RegularCollectionSchedule"
        case recyclingCollectionSchedule = "RecyclingCollectionSchedule"
        case organicsCollectionSchedule = "OrganicsCollectionSchedule"
        case formattedAddress = "FormattedAddress"
    }
}

extension Garbage {
    struct CodingData: Decodable {
        let bulkPickupCollectionSchedule, regularCollectionSchedule, recyclingCollectionSchedule, organicsCollectionSchedule: String
        let formattedAddress: String
        
        var garbage: Garbage {
            Garbage(bulkPickupCollectionSchedule: bulkPickupCollectionSchedule,
                    regularCollectionSchedule: regularCollectionSchedule,
                    recyclingCollectionSchedule: recyclingCollectionSchedule,
                    organicsCollectionSchedule: organicsCollectionSchedule,
                    formattedAddress: formattedAddress
            )
        }
    }
}
