//
//  NetworkManager.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/7/23.
//

import Foundation
import UIKit
import SODAKit

class NetworkManager {
    static let shared = NetworkManager()
    let decoder = JSONDecoder()
    let collectionURL = "https://a827-donatenyc.nyc.gov/DSNYGeoCoder/api/DSNYCollection/CollectionSchedule?address="
    
    func getGarbageDetails(atAddress addressString: String) async throws -> Garbage {
        
        guard let searchableAddress = collectionURL.appending(addressString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { throw NetworkError.invalidURL }
        guard let url = URL(string: searchableAddress) else { throw NetworkError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        do {
            let garbage = try decoder.decode(Garbage.self, from: data)
            print(garbage)
            return garbage
        } catch {
            throw NetworkError.invalidRepoData
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidRepoData
}
