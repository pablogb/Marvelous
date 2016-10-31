//
//  CachedResponse+CoreDataProperties.swift
//  MarvelSDK
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import Foundation
import CoreData


extension CachedResponse {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "CachedResponse");
    }

    @NSManaged public var path: String?
    @NSManaged public var parameters: String?
    @NSManaged public var cacheDate: NSDate?
    @NSManaged public var etag: String?
    @NSManaged public var entityType: String?

}
