//
//  ItemToDispose.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/25/23.
//

import Foundation

// MARK: - ItemToDisposeElement
struct ItemToDisposeElement: Codable, Identifiable {
    let id = UUID()
    let header, excerpt, content, name: String?
    let postType: String?
    let linkedPage: LinkedPageUnion?
    let otherSearchWords, keyWords: String?

    enum CodingKeys: String, CodingKey {
        case header, excerpt, content, name
        case postType = "post_type"
        case linkedPage = "linked_page"
        case otherSearchWords = "other_search_words"
        case keyWords = "key_words"
    }
}

enum LinkedPageUnion: Codable {
    case bool(Bool)
    case linkedPageClass(LinkedPageClass)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(LinkedPageClass.self) {
            self = .linkedPageClass(x)
            return
        }
        throw DecodingError.typeMismatch(LinkedPageUnion.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for LinkedPageUnion"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .linkedPageClass(let x):
            try container.encode(x)
        }
    }
}

// MARK: - LinkedPageClass
struct LinkedPageClass: Codable, Identifiable {
    let id: Int?
    let title, name, excerpt, type: String?
    let url: String?
}

typealias ItemsToDispose = [ItemToDisposeElement]
