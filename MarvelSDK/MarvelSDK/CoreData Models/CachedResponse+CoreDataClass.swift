//
//  CachedResponse+CoreDataClass.swift
//  MarvelSDK
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import Foundation
import CoreData

enum EntityType: String {
    case MarvelCharacter = "MarvelCharacter"
}

@objc(CachedResponse)
public class CachedResponse: NSManagedObject {
    // Deletes all objects associated with this cache, and deletes itself.
    func invalidate() {
        // Delete associated objects.
        let fetchRequest = NSFetchRequest(entityName: entityType!) as NSFetchRequest
        fetchRequest.predicate = NSPredicate(format: "cachedResponse = %@", self)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try CoreDataStack.sharedStack.context.executeRequest(deleteRequest)
        } catch let error as NSError {
            print("Could not delete objects associated to cache: \(error.localizedDescription)")
        }
        
        // Delete the cache request.
        CoreDataStack.sharedStack.context.deleteObject(self)
    }
}
