//
//  CoreDataStack.swift
//  MarvelSDK
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import CoreData

// TODO: Better error handling.

/// Manages all the set up for Core Data.
class CoreDataStack {
    
    let modelName = "ResponseCache"
    
    static var sharedStack:CoreDataStack = CoreDataStack()
    
    lazy var context: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.psc
        
        return managedObjectContext
    }()
    
    private lazy var psc: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let url = self.applicationCachesDirectory.URLByAppendingPathComponent(self.modelName)
        
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption : true]
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        }  catch let error as NSError {
            print("Could not add persistant store: \(error.localizedDescription)")
        }
        
        return coordinator
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle(forClass: self.dynamicType).URLForResource(self.modelName, withExtension: "momd")!
       
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    private lazy var applicationCachesDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        
        return urls[urls.count-1] as NSURL
    }()
        
    func saveContext () {
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not save context: \(error.localizedDescription)")
            }
        }
    }
}

