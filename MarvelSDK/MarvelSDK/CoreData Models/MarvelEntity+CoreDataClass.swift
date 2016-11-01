//
//  MarvelEntity+CoreDataClass.swift
//  MarvelSDK
//
//  Created by Pablo Gomez Basanta on 10/31/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData
import SwiftyJSON

@objc(MarvelEntity)
public class MarvelEntity: NSManagedObject {
    func populateFromJSON(json:JSON) {
        marvelId = json["id"].int64Value
        
        name = json["name"].string
        
        resourceURI = json["resourceURI"].string
        
        thumbnailBase = json["thumbnail"]["path"].string
        thumbnailExtension = json["thumbnail"]["extension"].string
        
        let jsonURLArray = json["urls"].array
        
        if let jsonURLArray = jsonURLArray {
            var urlArray = [LabeledURL]()
            
            for urlJSON in jsonURLArray {
                if let url = NSURL(string: urlJSON["url"].stringValue) {
                    urlArray.append(LabeledURL(url: url, label: urlJSON["type"].stringValue))
                }
            }
            
            urls = urlArray
        }
    }
    
    public func squareThumbURL() -> NSURL? {
        if thumbnailBase == nil || thumbnailExtension == nil { return nil}
        else { return NSURL(string: "\(thumbnailBase!)/standard_fantastic.\(thumbnailExtension!)") }
    }
    
    public func detailThumbURL() -> NSURL? {
        if thumbnailBase == nil || thumbnailExtension == nil { return nil}
        else { return NSURL(string: "\(thumbnailBase!)/detail.\(thumbnailExtension!)") }
    }
}
