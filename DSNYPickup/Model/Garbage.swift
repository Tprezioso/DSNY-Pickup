//
//  GarbageCollection.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/13/23.
//


import Foundation

struct Garbage: Codable {
    let routingTime: RoutingTime?
    let bulkPickupCollectionSchedule, regularCollectionSchedule, recyclingCollectionSchedule, organicsCollectionSchedule: String?
    let formattedAddress: String?

    enum CodingKeys: String, CodingKey {
        case routingTime = "RoutingTime"
        case bulkPickupCollectionSchedule = "BulkPickupCollectionSchedule"
        case regularCollectionSchedule = "RegularCollectionSchedule"
        case recyclingCollectionSchedule = "RecyclingCollectionSchedule"
        case organicsCollectionSchedule = "OrganicsCollectionSchedule"
        case formattedAddress = "FormattedAddress"
    }
}

// MARK: - RoutingTime
struct RoutingTime: Codable {
    let commercialRoutingTime, residentialRoutingTime, mixedUseRoutingTime, additionalLinks: String?

    enum CodingKeys: String, CodingKey {
        case commercialRoutingTime = "CommercialRoutingTime"
        case residentialRoutingTime = "ResidentialRoutingTime"
        case mixedUseRoutingTime = "MixedUseRoutingTime"
        case additionalLinks = "AdditionalLinks"
    }
}
