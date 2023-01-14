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
    // https://data.cityofnewyork.us/resource/rv63-53db.json?district=QE07
    static let shared = NetworkManager()
//    let client = SODAClient(domain: "data.cityofnewyork.us", token: APIToken.token)
    let decoder = JSONDecoder()
    
//    var data: [[String: Any]]! = []
    
//    func getData() {
//        let districts = client.query(dataset: "rv63-53db")
//
//        districts.orderDescending("district").get { res in
//            switch res {
//            case .dataset (let data):
//                // Update our data
//                self.data = data
//                print(data.first!)
//            case .error (let err):
//                let errorMessage = (err as NSError).userInfo.debugDescription
//                print(errorMessage)
//            }
//        }
//    }
    
    func getGarbageDetails(atUrl urlString: String) async throws -> Garbage {
            guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
            
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


//"multipolygon": {
//    coordinates =     (
//                (
//                        (
//                                (
//                    "-73.91329304299995",
//                    "40.70432089600007"
//                )

//https://data.cityofnewyork.us/resource/rv63-53db.json?$where=within_circle(multipolygon, 47.59, -122.33, 1000)

//https://data.cityofnewyork.us/resource/rv63-53db.json?$where=within_circle(multipolygon,%2040.70432089600007,%20-73.91329304299995,%201000)
