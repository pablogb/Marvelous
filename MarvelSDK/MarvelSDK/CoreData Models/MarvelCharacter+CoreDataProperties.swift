//
//  MarvelCharacter+CoreDataProperties.swift
//  MarvelSDK
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import Foundation
import CoreData


extension MarvelCharacter {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "MarvelCharacter");
    }

    @NSManaged public var marvelId: Int64
    @NSManaged public var name: String?
    @NSManaged public var desc: String?
    @NSManaged public var resourceURI: String?
    @NSManaged public var thumbnailBase: String?
    @NSManaged public var thumbnailExtension: String?
    @NSManaged public var urls: NSObject?
    @NSManaged public var modified: NSDate?
    @NSManaged public var cachedOrder: Int16
    @NSManaged public var cachedResponse: CachedResponse?

}
