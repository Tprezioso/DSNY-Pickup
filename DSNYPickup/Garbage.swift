//
//  GarbageCollection.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/13/23.
//


import Foundation

//struct GarbageElement: Codable {
//    let district, fid, frequency, freqBulk: String
//    let freqRecycling, freqRefuse, globalid, schedulecode: String
//    let section, shapeArea, shapeLength: String
//    let multipolygon: Multipolygon
//
//    enum CodingKeys: String, CodingKey {
//        case district, fid, frequency
//        case freqBulk = "freq_bulk"
//        case freqRecycling = "freq_recycling"
//        case freqRefuse = "freq_refuse"
//        case globalid, schedulecode, section
//        case shapeArea = "shape_area"
//        case shapeLength = "shape_length"
//        case multipolygon
//    }
//}
//
//// MARK: - Multipolygon
//struct Multipolygon: Codable {
//    let type: String
//    let coordinates: [[[[Double]]]]
//}
//
//typealias Garbage = [GarbageElement]

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
