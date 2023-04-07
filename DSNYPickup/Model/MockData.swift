//
//  MockData.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/27/23.
//

import Foundation
struct MockData {
    static let detailSearchItemToDispose = ItemToDispose(
        header: "Test", excerpt: "alskdjfhlaskdjfhlaksjdhflaskjhflaksjdhflaskdjfh", content: "qiwopeuryoqwieuryoq", name: "Test Name", postType: "disposal_specific", linkedPage: nil, otherSearchWords: "test other", keyWords: "Test Keyword", url: "")
    
    static let garbageCollection = Garbage(routingTime: RoutingTime(commercialRoutingTime: "", residentialRoutingTime: "", mixedUseRoutingTime: "", additionalLinks: ""), bulkPickupCollectionSchedule: "", regularCollectionSchedule: "", recyclingCollectionSchedule: "", organicsCollectionSchedule: "", formattedAddress: "65-25 160th street")
}
