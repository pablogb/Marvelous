//
//  MarvelSDK.swift
//  MarvelSDK
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CryptoSwift

import CoreData

/// MarvelSDK handles all communication with the Marvel API and manages the cache of responses.
public class MarvelSDK {
    public static var publicAPIKey:String! = nil
    public static var privateAPIKey:String! = nil
    
    let publicKey:String!
    let privateKey:String!
    
    init() {
        assert(MarvelSDK.publicAPIKey != nil && MarvelSDK.privateAPIKey != nil, "You must set MarvelSDK.publicAPIKey and MarvelSDK.privateAPIKey before using the SDK.")
        publicKey = MarvelSDK.publicAPIKey
        privateKey = MarvelSDK.privateAPIKey
    }
    
    /**
     Returns the shared instance of `MarvelSDK` ready to be used.
     
     - Warning: You must set `MarvelSDK.publicAPIKey` and `MarvelSDK.privateAPIKey` before calling accessing this property.
     
     */
    public static let sharedInstance = MarvelSDK()
    
    func makeAPICall(entityType:EntityType, path:String, parameters:[String: AnyObject]?, completionHandler: (statusCode:Int?, json:JSON?, error:ErrorType?, cachedResponse:CachedResponse?) -> Void) {
        
        var parameters:[String: AnyObject]! = parameters
        if parameters == nil { parameters = [:] }
        
        var parameterString = "" // Only used as a key for the cache.

        for (key, value) in parameters {
            parameterString += "\(key):\(value)"
        }

        var cached = cachedResponse(forPath: path, parameters: parameterString)
        
        var headers:[String : String]?
        
        if let cached = cached {
            // We have a cached response, check if it is still valid.
            print("cache is \(cached.cacheDate?.timeIntervalSinceNow) seconds old")
            if cached.cacheDate?.timeIntervalSinceNow > -86400 { // Less than 24 hours, use the cache.
                print("returned cached results")
                completionHandler(statusCode: nil, json: nil, error: nil, cachedResponse: cached)
                return
            } else if let etag = cached.etag {
                headers = ["If-None-Match": etag]
            }
        }
        
        // No cached response, or cache is no longer valid, contact the API.
        
        let now = NSDate()
        
        let ts = "\(now.timeIntervalSince1970)"
        
        parameters["ts"] = ts
        parameters["apikey"] = publicKey
        parameters["hash"] = "\(ts)\(privateKey)\(publicKey)".md5()
        
        let fullURL = "https://gateway.marvel.com/v1/public/\(path)"
        
        Alamofire.request(.GET, fullURL, parameters: parameters, headers:headers).responseJSON { response in
            if response.response?.statusCode == 304 { // Cache is still valid, update the cache date and return cached results.
                cached?.cacheDate = now
                CoreDataStack.sharedStack.saveContext()
                
                print("cache is still valid, extend it, and return cached results")
                completionHandler(statusCode: nil, json: nil, error: nil, cachedResponse: cached)
            } else if response.response?.statusCode == 200 { // New data, invalidate the prvious cache, create a new one, and return.
                if let data = response.result.value {
                    let json = JSON(data)
                    
                    cached?.invalidate()
                    
                    let moc = CoreDataStack.sharedStack.context
                    
                    cached = CachedResponse(entity: CachedResponse.entity(), insertIntoManagedObjectContext: moc)
                    cached!.path = path
                    cached!.parameters = parameterString
                    cached!.cacheDate = now
                    cached!.entityType = entityType.rawValue
                    cached!.etag = json["etag"].string
                    
                    print("new data returned")
                    completionHandler(statusCode: 200, json: json, error: nil, cachedResponse: cached)
                } else {
                    // Failed to parse JSON data, treat is as an internal error.
                    print("failed to parse json data")
                    completionHandler(statusCode: 500, json: nil, error: nil, cachedResponse: cached)
                }
            } else { // An error occured, send error data and cached version if available.
                print("an error occured")
                completionHandler(statusCode: response.response?.statusCode, json: nil, error: response.result.error, cachedResponse: cached)
            }
        }
    }
    
    func cachedResponse(forPath path:String, parameters:String) -> CachedResponse? {
        let fetchRequest = NSFetchRequest(entityName: "CachedResponse") as NSFetchRequest
        fetchRequest.predicate = NSPredicate(format: "path = %@ and parameters = %@", path, parameters)
        fetchRequest.fetchLimit = 1
        
        do {
            let fetchedObjects = try CoreDataStack.sharedStack.context.executeFetchRequest(fetchRequest)
            
            if let _ = fetchedObjects.first as? CachedResponse { print("found previous cache") } else { print("no previous cache") }
            
            return fetchedObjects.first as? CachedResponse
        } catch let error as NSError {
            print("Could not fetch results: \(error)")
            return nil
        }
    }
    
    public func characters(limit limit:Int?, offset:Int?, nameStartsWith:String?, completionHandler: (error:MarvelSDKError?, characters:[MarvelCharacter]) -> Void) {
        var parameters = [String: AnyObject]()
        
        if let limit = limit { parameters["limit"] = limit }
        if let offset = offset { parameters["offset"] = offset }
        if let nameStartsWith = nameStartsWith { parameters["nameStartsWith"] = nameStartsWith }
        
        makeAPICall(.MarvelCharacter, path: "characters", parameters: parameters) { (statusCode, json, error, cachedResponse) in
            if statusCode != 200 && cachedResponse == nil {
                // An error occured and no data was returned (not even cached data).
                let error:MarvelSDKError!
                
                if statusCode == nil { error = .NoResponse }
                else if statusCode == 429 { error = .RateLimitReached }
                else { error = .InternalError }
                
                completionHandler(error: error, characters: [])
            } else if statusCode == 200 {
                // We got a new response from the API. Parse, store in cache, and return.
                let moc = CoreDataStack.sharedStack.context
                var characters = [MarvelCharacter]()
                
                let characterJSONs = json!["data"]["results"]
                
                for (index, characterJSON) in (characterJSONs.array?.enumerate())! {
                    let character = MarvelCharacter(entity: MarvelCharacter.entity(), insertIntoManagedObjectContext: moc)
                    character.populateFromJSON(characterJSON as! JSON)
                    character.cachedOrder = Int16(index)
                    character.cachedResponse = cachedResponse!
                    
                    characters.append(character)
                }
                
                CoreDataStack.sharedStack.saveContext()
                
                completionHandler(error: nil, characters: characters)
            } else if let cachedResponse = cachedResponse {
                // No new data, but we can retrive the results from the cached response.
                let fetchRequest = NSFetchRequest(entityName: "MarvelCharacter") as NSFetchRequest
                fetchRequest.predicate = NSPredicate(format: "cachedResponse = %@", cachedResponse)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedOrder", ascending: true)]
                
                let fetchedObjects = (try? CoreDataStack.sharedStack.context.executeFetchRequest(fetchRequest)) as? [MarvelCharacter]
                
                if let fetchedObjects = fetchedObjects {
                    completionHandler(error: nil, characters: fetchedObjects)
                } else {
                    // Something went wrong :(
                    completionHandler(error: .InternalError, characters: [])
                }
            }
        }
    }
}
