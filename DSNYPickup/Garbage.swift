//
//  GarbageCollection.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/13/23.
//


import Foundation

struct Garbage: Codable {
    let bulkPickupCollectionSchedule, regularCollectionSchedule, recyclingCollectionSchedule, organicsCollectionSchedule: String
    let formattedAddress: String

    enum CodingKeys: String, CodingKey {
        case bulkPickupCollectionSchedule = "BulkPickupCollectionSchedule"
        case regularCollectionSchedule = "RegularCollectionSchedule"
        case recyclingCollectionSchedule = "RecyclingCollectionSchedule"
        case organicsCollectionSchedule = "OrganicsCollectionSchedule"
        case formattedAddress = "FormattedAddress"
    }
}
