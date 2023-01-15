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
    let collectionURL = "https://a827-donatenyc.nyc.gov/DSNYGeoCoder/api/DSNYCollection/CollectionSchedule?address="
    
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
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}
