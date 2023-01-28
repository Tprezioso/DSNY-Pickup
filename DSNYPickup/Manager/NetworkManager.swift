//
//  NetworkManager.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/7/23.
//

import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    let decoder = JSONDecoder()
    static let baseURL = "https://www1.nyc.gov/assets/dsny/site/"
    let collectionURL = "https://a827-donatenyc.nyc.gov/DSNYGeoCoder/api/DSNYCollection/CollectionSchedule?address="
    let itemDisposalURL = "https://dsny.cityofnewyork.us/wp-json/dsny/v1/searchDisposalItems?s="
    
    func getGarbageDetails(atAddress addressString: String) async throws -> Garbage {
        
        guard let searchableAddress = collectionURL.appending(addressString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print(" ❌ Invalid URL")
            throw NetworkError.invalidURL
        }
        guard let url = URL(string: searchableAddress) else { throw NetworkError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print(" ❌ Invalid Response")
            throw NetworkError.invalidResponse
        }
        
        do {
            let garbage = try decoder.decode(Garbage.self, from: data)
            print(garbage)
            return garbage
        } catch {
            print(" ❌ Invalid Data")
            throw NetworkError.invalidData
        }
    }
    
    func getItemDisposalDetails(for itemString: String) async throws -> ItemsToDispose {
        
        guard let searchableAddress = itemDisposalURL.appending(itemString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print(" ❌ Invalid URL")
            throw NetworkError.invalidURL
        }
        guard let url = URL(string: searchableAddress) else { throw NetworkError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print(" ❌ Invalid Response")
            throw NetworkError.invalidResponse
        }
        
        do {
            let itemToDispose = try decoder.decode(ItemsToDispose.self, from: data)
            print(itemToDispose)
            return itemToDispose
        } catch {
            print(" ❌ Invalid Data")
            throw NetworkError.invalidData
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}
