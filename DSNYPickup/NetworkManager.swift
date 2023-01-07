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
    let client = SODAClient(domain: "data.cityofnewyork.us", token: APIToken.token)
    var data: [[String: Any]]! = []
    
    func getData() {
        let districts = client.query(dataset: "rv63-53db")
        
        districts.orderDescending("district").get { res in
            switch res {
            case .dataset (let data):
                // Update our data
                self.data = data
                print(data)
            case .error (let err):
                let errorMessage = (err as NSError).userInfo.debugDescription
                print(errorMessage)
            }
        }
    }
}
