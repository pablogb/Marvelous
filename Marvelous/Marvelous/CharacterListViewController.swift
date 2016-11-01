//
//  CharacterListViewController.swift
//  Marvelous
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import UIKit
import MarvelSDK

class CharacterListViewController: UIViewController {
    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var searchBarContainer:UIView!
    
    var characters:[MarvelCharacter] = []
    
    // Paging
    let limit = 100
    var offset = 0
    var moreCharacters = true
    var loadingNext = false
    
    // Filter and search
    let searchLimit = 100
    let filterLimit = 50
    var filteredCharacters:[MarvelCharacter]? = nil
    var searchController = UISearchController(searchResultsController: nil)
    var searching = false
    var lastSearchText:String? = nil
    var searchTextTimer:NSTimer? = nil
    var searchResultCharacters:[MarvelCharacter]? = nil
    var searchResultString:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure searchController
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchBarContainer.addSubview(searchController.searchBar)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showCharacterDetail" {
            let character = sender as? MarvelCharacter
            let destination = segue.destinationViewController as! CharacterDetailViewController
            
            destination.character = character
        }
    }
    
    func loadNextCharacters() {
        
        if loadingNext == false {
            loadingNext = true
            
            MarvelSDK.sharedInstance.characters(limit: limit, offset: offset, nameStartsWith: nil) { [weak self] (error, characters) in
                if let vc = self {
                    if characters.count == vc.limit {
                        print("more characters left")
                        vc.moreCharacters = true
                    } else {
                        print("no more characters")
                        vc.moreCharacters = false
                    }
                    
                    vc.offset += vc.limit
                    
                    let oldCount = vc.characters.count
                    
                    vc.characters.appendContentsOf(characters)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        var indexPaths:[NSIndexPath] = []
                        
                        for (index, _) in characters.enumerate() {
                            indexPaths.append(NSIndexPath(forRow: oldCount + index, inSection: 0))
                        }
                        
                        if vc.moreCharacters == false {
                            // Remove the loading cell and add new cells.
                            vc.collectionView?.performBatchUpdates({
                                vc.collectionView?.deleteItemsAtIndexPaths([NSIndexPath(forRow: oldCount, inSection: 0)])
                                vc.collectionView?.insertItemsAtIndexPaths(indexPaths)
                            }, completion: nil)
                        } else {
                            // Just add new cells.
                            vc.collectionView?.insertItemsAtIndexPaths(indexPaths)
                        }
                    })
                    
                    vc.loadingNext = false
                }
                
            }
        }
    }
}

extension CharacterListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let filteredCharacters = filteredCharacters {
            if searching { return filteredCharacters.count + 1}
            else { return filteredCharacters.count }
        }
        else if moreCharacters { return characters.count + 1 }
        else { return characters.count }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let character = characterFor(indexPath: indexPath)
        if let character = character { // Return entity cell.
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("entityCell", forIndexPath: indexPath) as! EntityCollectionViewCell
            
            cell.configure(entity: character)
            
            return cell
        } else { // Return Loading cell.
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("loadingCell", forIndexPath: indexPath) as! LoadingCollectionViewCell
            cell.activityIndicator.startAnimating()
            
            if filteredCharacters == nil { // If this is the end of page loading cell, then start loading the next page.
                loadNextCharacters()
            }
            
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)

        // Do nothing if the user selected a loading cell.
        if let character = characterFor(indexPath: indexPath) {
            performSegueWithIdentifier("showCharacterDetail", sender: character)
        }
    }
    
    func characterFor(indexPath indexPath:NSIndexPath) -> MarvelCharacter? {
        if let filteredCharacters = filteredCharacters {
            var arrayIndex = indexPath.row
            if searching {
                arrayIndex -= 1
            }
            if arrayIndex < 0 { // Display loading cell.
                return nil
            } else { // Display character cell
                return filteredCharacters[arrayIndex]
            }
        } else {
            if indexPath.row == characters.count { // Display loading cell.
                return nil
            } else { // Display entitiy cell
                return characters[indexPath.row]
            }
        }
    }
}

extension CharacterListViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchText = searchController.searchBar.text!
        // TODO: Filter when going forward, discard search when going back.
        searchTextTimer?.invalidate()
        lastSearchText = searchText
        
        if searchText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) != "" {
            // When returning from a presented view the search is triggered again, but the search string did not change.
            if searchText != searchResultString {
                searching = true
                searchTextTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, repeats: false) { [weak self] (timer) in
                    print("begin search for \(searchText)")
                    self?.searching = true
                    
                    MarvelSDK.sharedInstance.characters(limit: self?.searchLimit, offset: 0, nameStartsWith: searchText, completionHandler: { (error, characters) in
                        if self?.lastSearchText == searchText {
                            print("done searching for \(searchText), display results")
                            self?.searching = false
                            
                            self?.searchResultString = searchText
                            self?.searchResultCharacters = characters
                            
                            self?.updatedFilteredCharacters()
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self?.collectionView.reloadData()
                            })
                        } else {
                            print("done searching for \(searchText) but results are no longer valid")
                        }
                    })
                }
                
                updatedFilteredCharacters()
            }
        } else {
            searching = false
            filteredCharacters = nil
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.collectionView.reloadData()
        })
    }
    
    func updatedFilteredCharacters() {
        if let lastSearchText = lastSearchText {
            // Get the most recent characters from the cache.
            let charactersFromCache = MarvelSDK.sharedInstance.filteredCharactersFromCache(searchText: lastSearchText, limit: filterLimit)
            
            // If all else fails, at least use the characters we can get from the cache.
            var newFilteredCharacters = charactersFromCache
            
            // Try to use serach results if we have them.
            if let searchResultString = searchResultString, let searchResultCharacters = searchResultCharacters {
                // Check if the searchResults we have are still relevant to our current search.
                if lastSearchText.hasPrefix(searchResultString) {
                    var newSearchResults = searchResultCharacters
                    // Search strings have the same prefix, but our current search is further along. We should filter searchResultCharacters according to the new search text.
                    if searchResultString != lastSearchText {
                        newSearchResults = []
                        
                        // Check if the name contains all words in the search string.
                        let words = lastSearchText.componentsSeparatedByString(" ")
                        for character in searchResultCharacters {
                            var nameContainsAllWords = true
                            for word in words {
                                if character.name!.rangeOfString(word, options: [.DiacriticInsensitiveSearch, .CaseInsensitiveSearch]) == nil {
                                    nameContainsAllWords = false
                                    break
                                }
                            }
                            if nameContainsAllWords {
                                newSearchResults.append(character)
                            }
                        }
                    }
                    
                    // Merge newSearchResults with charactersFromCache
                    var addedIds = Set<Int64>()
                    newFilteredCharacters = []
                    
                    for character in newSearchResults {
                        if !addedIds.contains(character.marvelId) {
                            newFilteredCharacters.append(character)
                            addedIds.insert(character.marvelId)
                        }
                    }
                    
                    for character in charactersFromCache {
                        if !addedIds.contains(character.marvelId) {
                            newFilteredCharacters.append(character)
                            addedIds.insert(character.marvelId)
                        }
                    }
                    
                }
            }
            
            filteredCharacters = newFilteredCharacters
        }
    }
    
    func willDismissSearchController(searchController: UISearchController) {
        searching = false
        filteredCharacters = nil
        
        // Characters from searches are not cached, the SDK automatically clears them
        // when initialized, but it's a good idea to also clear them here.
        MarvelSDK.sharedInstance.clearUncachedCharacters()
    }
}
