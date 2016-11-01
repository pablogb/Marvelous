//
//  Models.swift
//  MarvelSDK
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import Foundation

public enum MarvelSDKError {
    case NoResponse
    case RateLimitReached
    case InternalError
}

public class LabeledURL: NSObject, NSCoding {
    public var url:NSURL
    public var label:String
    
    public init(url: NSURL, label: String) {
        self.url = url
        self.label = label
    }
    
    public required convenience init?(coder decoder: NSCoder) {
        guard
            let url = decoder.decodeObjectForKey("url") as? NSURL,
            let label = decoder.decodeObjectForKey("label") as? String
        else { return nil }
        
        self.init(url: url, label: label)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.url, forKey: "url")
        coder.encodeObject(self.label, forKey: "label")
    }
}
