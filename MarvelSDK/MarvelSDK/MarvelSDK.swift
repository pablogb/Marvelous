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
        
        // Clean up the cache.
        // TODO: Clear old entries from the cache.
        
        clearUncachedCharacters()
    }
    
    /**
     Returns the shared instance of `MarvelSDK` ready to be used.
     
     - Warning: You must set `MarvelSDK.publicAPIKey` and `MarvelSDK.privateAPIKey` before calling accessing this property.
     
     */
    public static let sharedInstance = MarvelSDK()
    
    
    /**
     Calls the Marvel API with the specified parameters.
     
     - Parameter: entityType The type of entity expected from the API results, used by the caching system to find entities beloging to a cache.
     - Parameter: path The API path you wish to query.
     - Parameter: parameters Parameters for the API call.
     - Parameter: shouldCache Determines whether the results should be cached or not.
     - Parameter: completionHandler The completion handler to be called when the server response is received.
     
     */
    func makeAPICall(entityType:EntityType, path:String, parameters:[String: AnyObject]?, shouldCache:Bool = true, completionHandler: (statusCode:Int?, json:JSON?, error:ErrorType?, cachedResponse:CachedResponse?) -> Void) {
        
        var parameters:[String: AnyObject]! = parameters
        if parameters == nil { parameters = [:] }
        
        var parameterString = "" // Only used as a key for the cache.

        for (key, value) in parameters {
            parameterString += "\(key):\(value)"
        }
        
        var cached:CachedResponse? = nil
        if shouldCache {
            cached = cachedResponse(forPath: path, parameters: parameterString)
        }
        
        var headers:[String : String]?
        
        if let cached = cached {
            // We have a cached response, check if it is still valid.
            if cached.cacheDate?.timeIntervalSinceNow > -86400 { // Less than 24 hours, use the cache.
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
                
                completionHandler(statusCode: nil, json: nil, error: nil, cachedResponse: cached)
            } else if response.response?.statusCode == 200 { // New data, invalidate the prvious cache, create a new one, and return.
                if let data = response.result.value {
                    let json = JSON(data)
                    
                    if shouldCache {
                        cached?.invalidate()
                        
                        let moc = CoreDataStack.sharedStack.context
                        
                        cached = CachedResponse(entity: CachedResponse.entity(), insertIntoManagedObjectContext: moc)
                        cached!.path = path
                        cached!.parameters = parameterString
                        cached!.cacheDate = now
                        cached!.entityType = entityType.rawValue
                        cached!.etag = json["etag"].string
                    }
                    
                    completionHandler(statusCode: 200, json: json, error: nil, cachedResponse: cached)
                } else {
                    // Failed to parse JSON data, treat is as an internal error.
                    completionHandler(statusCode: 500, json: nil, error: nil, cachedResponse: cached)
                }
            } else { // An error occured, send error data and cached version if available.
                completionHandler(statusCode: response.response?.statusCode, json: nil, error: response.result.error, cachedResponse: cached)
            }
        }
    }
    
    /**
     Returns a `CachedResponse` object for the given path and parameters, if available. Returns `nil` if no cache is available.
     
     - Parameter: path The path of the request.
     - Parameter: parameters Parameters used for the request.
     
     - Returns: A `CachedResponse` object if this request is in the cache, `nil` if not.
     
     */
    func cachedResponse(forPath path:String, parameters:String) -> CachedResponse? {
        let fetchRequest = NSFetchRequest(entityName: "CachedResponse") as NSFetchRequest
        fetchRequest.predicate = NSPredicate(format: "path = %@ and parameters = %@", path, parameters)
        fetchRequest.fetchLimit = 1
        
        do {
            let fetchedObjects = try CoreDataStack.sharedStack.context.executeFetchRequest(fetchRequest)
            return fetchedObjects.first as? CachedResponse
        } catch let error as NSError {
            print("Could not fetch results: \(error)")
            return nil
        }
    }
    
    /**
     Retrieves a collection of entities from an API endpoint.
     
     - Parameter: T The Core Data type of the entity returned by the end point.
     - Parameter: entityType The type of entity expected from the API results, used by the caching system to find entities beloging to a cache.
     - Parameter: path The API path you wish to query.
     - Parameter: limit The maximum number of objects that should be returned by the API.
     - Parameter: offset The offset from the first result, used by the API for paging.
     - Parameter: nameStartsWith A string to filter the entities by.
     - Parameter: completionHandler The completion handler to be called when the server response is received.
    
     */
    func entities<T: MarvelEntity>(entityType:EntityType, path:String, limit limit:Int?, offset:Int?, nameStartsWith:String?, completionHandler: (error:MarvelSDKError?, entities:[T]) -> Void) {
        // TODO: Validate that limit and offset are within bounds.
        var parameters = [String: AnyObject]()
        var shouldCache = true
        
        if let limit = limit { parameters["limit"] = limit }
        if let offset = offset { parameters["offset"] = offset }
        if let nameStartsWith = nameStartsWith {
            parameters["nameStartsWith"] = nameStartsWith
            shouldCache = false
        }
        
        makeAPICall(entityType, path: path, parameters: parameters, shouldCache: shouldCache) { (statusCode, json, error, cachedResponse) in
            if statusCode != 200 && cachedResponse == nil {
                // An error occured and no data was returned (not even cached data).
                let error:MarvelSDKError!
                
                if statusCode == nil { error = .NoResponse }
                else if statusCode == 429 { error = .RateLimitReached }
                else { error = .InternalError }
                
                completionHandler(error: error, entities: [])
            } else if statusCode == 200 {
                // We got a new response from the API. Parse, store in cache, and return.
                let moc = CoreDataStack.sharedStack.context
                
                var entities = [T]()
                
                let entityJSONs = json!["data"]["results"]
                
                let now = NSDate()
                for (index, entityJSON) in (entityJSONs.array?.enumerate())! {
                    //let entity = T(entity: T.entity(), insertIntoManagedObjectContext: moc)
                    let entity = T(context: moc)
                    entity.populateFromJSON(entityJSON as! JSON)
                    entity.cachedOrder = Int16(index)
                    entity.cachedResponse = cachedResponse
                    entity.cacheDate = now
                    
                    entities.append(entity)
                }
                
                CoreDataStack.sharedStack.saveContext()
                
                completionHandler(error: nil, entities: entities)
            } else if let cachedResponse = cachedResponse {
                // No new data, but we can retrive the results from the cached response.
                let fetchRequest = NSFetchRequest(entityName: entityType.rawValue) as NSFetchRequest
                fetchRequest.predicate = NSPredicate(format: "cachedResponse = %@", cachedResponse)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedOrder", ascending: true)]
                
                let fetchedObjects = (try? CoreDataStack.sharedStack.context.executeFetchRequest(fetchRequest)) as? [T]
                
                if let fetchedObjects = fetchedObjects {
                    completionHandler(error: nil, entities: fetchedObjects)
                } else {
                    // Something went wrong :(
                    completionHandler(error: .InternalError, entities: [])
                }
            }
        }
    }
    
    /**
     Retrieves a collection of characters from the API.
     
     - Parameter limit: The maximum number of objects that should be returned by the API.
     - Parameter offset: The offset from the first result, used by the API for paging.
     - Parameter nameStartsWith: A string to filter the entities by.
     - Parameter completionHandler: The completion handler to be called when the server response is received.
     
     */
    public func characters(limit limit:Int?, offset:Int?, nameStartsWith:String?, completionHandler: (error:MarvelSDKError?, characters:[MarvelCharacter]) -> Void) {
        entities(.MarvelCharacter, path: "characters", limit: limit, offset: offset, nameStartsWith: nameStartsWith) { (error, entities:[MarvelCharacter]) in
            completionHandler(error: error, characters: entities)
        }
    }
    
    /**
     Retrieves a collection of characters found in the cache whose name matched `searchText`
     
     - Parameter searchText: The text to search for. The text is separated into words and the character name must contain each word.
     - Parameter limit: The maximum number of characters that should be returned
     
     - Returns: An array of characters whose name matches `searchText`
     */
    public func filteredCharactersFromCache(searchText searchText:String, limit:Int = 50) -> [MarvelCharacter] {
        let fetchRequest = NSFetchRequest(entityName: "MarvelCharacter") as NSFetchRequest
        
        // Generate predicate for word-by-word search.
        let words = searchText.componentsSeparatedByString(" ")
        
        //var format = "cachedResponse != nil "
        var format = ""
        var arguments:[String] = []
        for (index, word) in words.enumerate() {
            if word != "" {
                if index == 0 { format += "%K CONTAINS[cd] %@" }
                else { format += "AND %K CONTAINS[cd] %@" }
                
                arguments.append("name")
                arguments.append(word)
            }
        }
        
        let predicate = NSPredicate(format: format, argumentArray: arguments)
        fetchRequest.predicate = predicate
        // Entries in the cache might be repeatad, prioritize entries in a cache (less likely to be repeated) then prioritize by date (newer entries from search results are more likely to be relevant)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedResponse", ascending: false), NSSortDescriptor(key: "cacheDate", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.fetchLimit = limit
                
        do {
            let fetchedObjects = try CoreDataStack.sharedStack.context.executeFetchRequest(fetchRequest)
            
            let characters = (fetchedObjects as? [MarvelCharacter]) ?? []
            var addedIds = Set<Int64>()
            var uniqueCharacters:[MarvelCharacter] = []
            
            for character in characters {
                if !addedIds.contains(character.marvelId) {
                    uniqueCharacters.append(character)
                    addedIds.insert(character.marvelId)
                }
            }
            
            return uniqueCharacters
        } catch let error as NSError {
            print("Could not fetch results: \(error)")
            return []
        }
    }
    

    /// Removes Characters found in the Core Data cache which are not associated to any cache.
    public func clearUncachedCharacters() {
        let fetchRequest = NSFetchRequest(entityName: "MarvelCharacter") as NSFetchRequest
        fetchRequest.predicate = NSPredicate(format: "cachedResponse = nil")
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try CoreDataStack.sharedStack.context.executeRequest(deleteRequest)
        } catch let error as NSError {
            print("Could not delete objects associated to cache: \(error.localizedDescription)")
        }
    }
}
