//
//  MarvelEntity+CoreDataProperties.swift
//  MarvelSDK
//
//  Created by Pablo Gomez Basanta on 10/31/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension MarvelEntity {
    
    @NSManaged public var cachedOrder: Int16
    @NSManaged public var marvelId: Int64
    @NSManaged public var name: String?
    @NSManaged public var resourceURI: String?
    @NSManaged public var thumbnailBase: String?
    @NSManaged public var thumbnailExtension: String?
    @NSManaged public var urls: NSObject?
    @NSManaged public var cachedResponse: CachedResponse?

}
