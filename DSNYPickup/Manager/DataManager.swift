//
//  DataManager.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/29/23.
//

import Foundation
import CoreData

class DataManager: NSObject, ObservableObject {
    /// Dynamic properties that the UI will react to
    @Published var garbageCollectionItems: [GarbageCollection] = [GarbageCollection]()
    
    /// Add the Core Data container with the model name
    let container: NSPersistentContainer = NSPersistentContainer(name: "GarbageCollection")
    
    /// Default init method. Load the Core Data container
        override init() {
            super.init()
            container.loadPersistentStores { _, _ in }
        }
}
