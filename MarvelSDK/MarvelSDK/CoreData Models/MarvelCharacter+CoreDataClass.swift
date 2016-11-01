//
//  MarvelCharacter+CoreDataClass.swift
//  MarvelSDK
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

@objc(MarvelCharacter)
public class MarvelCharacter: MarvelEntity {
    override func populateFromJSON(json:JSON) {
        super.populateFromJSON(json)
        
        desc = json["description"].string
    }
    
    public func comics(limit limit:Int?, offset:Int?, completionHandler: (error:MarvelSDKError?, comics:[MarvelEntity]) -> Void) {
        MarvelSDK.sharedInstance.entities(.MarvelEntity, path: "characters/\(marvelId)/comics", limit: limit, offset: offset, nameStartsWith: nil) { (error, entities:[MarvelEntity]) in
            completionHandler(error: error, comics: entities)
        }
    }
    
    public func series(limit limit:Int?, offset:Int?, completionHandler: (error:MarvelSDKError?, series:[MarvelEntity]) -> Void) {
        MarvelSDK.sharedInstance.entities(.MarvelEntity, path: "characters/\(marvelId)/series", limit: limit, offset: offset, nameStartsWith: nil) { (error, entities:[MarvelEntity]) in
            completionHandler(error: error, series: entities)
        }
    }
    
    public func stories(limit limit:Int?, offset:Int?, completionHandler: (error:MarvelSDKError?, stories:[MarvelEntity]) -> Void) {
        MarvelSDK.sharedInstance.entities(.MarvelEntity, path: "characters/\(marvelId)/stories", limit: limit, offset: offset, nameStartsWith: nil) { (error, entities:[MarvelEntity]) in
            completionHandler(error: error, stories: entities)
        }
    }
    
    public func events(limit limit:Int?, offset:Int?, completionHandler: (error:MarvelSDKError?, events:[MarvelEntity]) -> Void) {
        MarvelSDK.sharedInstance.entities(.MarvelEntity, path: "characters/\(marvelId)/events", limit: limit, offset: offset, nameStartsWith: nil) { (error, entities:[MarvelEntity]) in
            completionHandler(error: error, events: entities)
        }
    }
}
