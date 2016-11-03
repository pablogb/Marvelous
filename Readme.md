# Marvelous

Marvelous is an iOS app to explore the characters in the Marvel Universe using the [Marvel API](https://developer.marvel.com).

## Getting Started

Before running Marvelous for the first time, it is important that you set up your API Keys on the project. To do so follow these instructions:

1. Duplicate `PrivateConstants.swift.example` found in `Marvelous/Marvelous` and rename it to `PrivateConstants.swift`.
2. Open the newly created `Marvelous/Marvelous/PrivateConstants.swift` and enter private and public API keys in the following lines:

	```swift
	MarvelSDK.publicAPIKey = nil
   MarvelSDK.privateAPIKey = nil
	```

## Dependencies

* [AlamoFire](https://github.com/Alamofire/Alamofire) for network requests.
* [SwiftJSON](https://github.com/SwiftyJSON/SwiftyJSON) to parse JSON responses.
* [SDWebImage](https://github.com/rs/SDWebImage) to defer loading of `UIImageView` and to cache all downloaded images.
* [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) to calculate MD5 hash required for authentication with the Marvel API.

	> MD5 hashes can be calculated using the native iOS implementation in `CommonCrypto/CommonCrypto.h`, however, CryptoSwift was used to simplify project setup (API calls are made within a framework and the proper setup to use an Objective-C library within a Swift framework is non-trivial). In the future, it would be advisable to remove the dependency to CryptoSwift in favor of the native MD5 implementation.
	
## Features

* API Response Caching: Calls to the API are cached using Core Data. Caches are valid for 24 hours (as suggested in the Marvel API documentation). When repeating a previously cached request, the `If-None-Match` header is used to ask the server if our cached version is still valid and reduce bandwidth usage if the information has not changed.
* Improved filtering and search: The only way of searching through results provided by the Marvel API is by using the `nameStartsWith` parameter. Unfortunately this is quite limiting. To help improve search results, Marvelous combines the API search results with full text search on all characters that have been previously cached. This results in a faster and more intuitive search experience.

	> The Marvel API documentation discourages fetching information not explicitly requested by the user, so unfortunately we may only rely on previously cached results to improve the search experience.
	
* Clean architecture: All interaction with the Marvel API is encapsulated inside a framework called `MarvelSDK`, encouraging reusability and separation of app logic and API communication logic.

## TO-DOs

Aspects that could be improved in a future version are:

* Improve error handling: Current error handling is very basic and could use some improvement.
* Make app universal / improve landscape layout
* Improve cache system: Currently the cache size is unlimited, which is far from ideal.
* Add Unit tests
* Improve documentation