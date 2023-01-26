//
//  ItemToDispose.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/25/23.
//

import Foundation

//   let itemToDispose = try? JSONDecoder().decode(ItemToDispose.self, from: jsonData)

// MARK: - ItemToDispose
struct ItemToDispose: Codable {
    let header, excerpt, content, name, postType: String
    let linkedPage: LinkedPage
    let otherSearchWords, keyWords: String

    enum CodingKeys: String, CodingKey {
        case header, excerpt, content, name
        case postType = "post_type"
        case linkedPage = "linked_page"
        case otherSearchWords = "other_search_words"
        case keyWords = "key_words"
    }
}

// MARK: - LinkedPage
struct LinkedPage: Codable {
    let id: Int
    let title, name, excerpt, type: String
    let url: String
}

typealias ItemsToDispose = [ItemToDispose]
