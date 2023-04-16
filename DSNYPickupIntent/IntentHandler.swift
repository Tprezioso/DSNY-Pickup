//
//  IntentHandler.swift
//  DSNYPickupWidgetExtension
//
//  Created by Thomas Prezioso Jr on 4/15/23.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}

extension IntentHandler: DSNYPickupIntentHandling {
    func providePickupLocationOptionsCollection(for intent: DSNYPickupIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
        
    }
    
    func provideParameterOptionsCollection(for intent: DSNYPickupIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {

    }
        private func getData() throws -> [GarbageCollection] {
        let context = DataManager.shared.container.viewContext
        let request = GarbageCollection.fetchRequest()
        let result = try context.fetch(request)
        return result
    }
    
    func provideRepoOptionsCollection(for intent: DSNYPickupIntent) async throws -> INObjectCollection<NSString> {
        // Get list of repos
        guard let collectionData = try? getData() else {
            return INObjectCollection(items: [""] as [NSString])
        }
        
        let collectionLocations = collectionData.compactMap { $0.formattedAddress }
        return INObjectCollection(items: collectionLocations as [NSString])
    }
    
    func defaultRepo(for intent: DSNYPickupIntent) -> String? { "1234 Main st, Flushing, NY 12345 USA" }
}
