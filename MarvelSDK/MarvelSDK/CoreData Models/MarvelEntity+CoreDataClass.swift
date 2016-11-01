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
    /**
     Fills out the information of this entity with the information contained in the JSON object.
     
     - Parameter json: The JSON object with the entity details
     */
    func populateFromJSON(json:JSON) {
        marvelId = json["id"].int64Value
        
        name = json["title"].string
        
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
    /**
     Returns the URL for the square image associated to this entity.
     
     - Returns: An `NSURL` object for the image.
     */
    public func squareThumbURL() -> NSURL? {
        if thumbnailBase == nil || thumbnailExtension == nil { return nil}
        else { return NSURL(string: "\(thumbnailBase!)/standard_fantastic.\(thumbnailExtension!)") }
    }
    
    /**
     Returns the URL for the full detailed image associated to this entity.
     
     - Returns: An `NSURL` object for the image.
     */
    public func detailThumbURL() -> NSURL? {
        if thumbnailBase == nil || thumbnailExtension == nil { return nil}
        else { return NSURL(string: "\(thumbnailBase!)/detail.\(thumbnailExtension!)") }
    }
    
    /**
     Returns the Marvel.com URL associated to this entity.
     
     - Returns: An `NSURL` object for the Marvel.com URL associated to this entity.
     */
    public func detailURL() -> NSURL? {
        let labeledURLs = urls as? [LabeledURL]
        var detailURL:NSURL?
        
        if let labeledURLs = labeledURLs {
            for labeledURL in labeledURLs {
                // Any URL works, but try to find the detail url.
                detailURL = labeledURL.url
                if labeledURL.label == "detail" { break }
            }
        }
        
        return detailURL
    }
}
