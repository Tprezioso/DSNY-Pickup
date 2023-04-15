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
    static let shared = DataManager()
    /// Add the Core Data container with the model name
    
    /// Default init method. Load the Core Data container
    override init() {
        super.init()
        container.loadPersistentStores { _, _ in }
    }
    
    let container: NSPersistentContainer = {
        let pc = NSPersistentContainer(name: "GarbageCollection")
        let storeURL = URL.storeURL(for: "group.com.Swifttom.DSNYPickup", databaseName: "group.com.Swifttom.DSNYPickup")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        pc.persistentStoreDescriptions = [storeDescription]
        pc.loadPersistentStores { _, error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        return pc
    }()
}

public extension URL {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}

