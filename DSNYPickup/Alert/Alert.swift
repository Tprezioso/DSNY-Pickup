//
//  Alert.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/15/23.
//

import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    let dismissButton: Alert.Button
}

struct AlertContext {
    
    // MARK: - Network Alerts
    static let invalidData = AlertItem(title: Text("Server Error Invalid Data"),
                                       message: Text("The data from the server was invalid. Please contact support"),
                                       dismissButton: .default(Text("OK")))

    static let invalidResponse = AlertItem(title: Text("Server Error Invalid Response"),
                                           message: Text("Invalid response from the server. Please try again later"),
                                           dismissButton: .default(Text("OK")))
    
    static let invalidURL = AlertItem(title: Text("Server Error Invalid URL"),
                                      message: Text("There was a issue connecting to the server. If this persists please contact support"),
                                      dismissButton: .default(Text("OK")))
    
    static let unableToComplete = AlertItem(title: Text("Error"),
                                            message: Text("Unable to complete the request at this time. Check internet connection"),
                                            dismissButton: .default(Text("OK")))

}
