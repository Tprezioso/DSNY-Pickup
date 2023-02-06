//
//  ItemToDispose.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/25/23.
//

import Foundation

// MARK: - ItemToDisposeElement
struct ItemToDispose: Identifiable {
    let id = UUID()
    let header, excerpt, content, name: String?
    let postType: String?
    let linkedPage: LinkedPageUnion?
    let otherSearchWords, keyWords: String?
    var url: String?
    
    init(header: String?, excerpt: String?, content: String?, name: String?, postType: String?, linkedPage: LinkedPageUnion?, otherSearchWords: String?, keyWords: String?, url: String?) {
        self.header = header
        self.excerpt = excerpt
        self.content = content
        self.name = name
        self.postType = postType
        self.linkedPage = linkedPage
        self.otherSearchWords = otherSearchWords
        self.keyWords = keyWords
        self.url = url
    }
    
//    enum CodingKeys: String, CodingKey {
//        case header, excerpt, content, name
//        case postType = "post_type"
//        case linkedPage = "linked_page"
//        case otherSearchWords = "other_search_words"
//        case keyWords = "key_words"
//    }
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

typealias ItemsToDispose = [ItemToDispose]

extension ItemToDispose: Decodable {
    struct CodingData: Decodable {
        let header, excerpt, content, name, url: String?
        let postType: String?
        let linkedPage: LinkedPageUnion?
        let otherSearchWords, keyWords: String?
        
        var itemToDispose: ItemToDispose {
            ItemToDispose(header: header, excerpt: excerpt, content: content, name: name, postType: postType, linkedPage: linkedPage, otherSearchWords: otherSearchWords, keyWords: keyWords, url: url)
        }
    }
}
