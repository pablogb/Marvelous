//
//  PrivateConstants.swift
//  Marvelous
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import Foundation
import MarvelSDK

func InitializePrivateConstants() {
    // Set your Marvel API public and private keys here before running the app!
    
    MarvelSDK.publicAPIKey = nil
    MarvelSDK.privateAPIKey = nil
    
    assert(MarvelSDK.publicAPIKey != nil && MarvelSDK.privateAPIKey != nil, "You must set MarvelSDK.publicAPIKey and MarvelSDK.privateAPIKey before running the app.")
}
