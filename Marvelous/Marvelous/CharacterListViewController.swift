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
    var filteredCharacters:[MarvelCharacter]? = nil
    var searchController = UISearchController(searchResultsController: nil)
    var searching = false
    var lastSearchText:String? = nil
    var searchTextTimer:NSTimer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchBarContainer.addSubview(searchController.searchBar)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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
                        //vc.collectionView?.reloadData()
                        
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
        if let filteredCharacters = filteredCharacters {
            var arrayIndex = indexPath.row
            if searching {
                arrayIndex -= 1
            }
            if arrayIndex < 0 { // Display loading cell.
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("loadingCell", forIndexPath: indexPath) as! LoadingCollectionViewCell
                cell.activityIndicator.startAnimating()
                
                return cell
            } else { // Display character cell
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("characterCell", forIndexPath: indexPath) as! CharacterCollectionViewCell
                
                cell.configure(character: filteredCharacters[arrayIndex])
                
                return cell
            }
            
        } else {
            if indexPath.row == characters.count { // Display loading cell.
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("loadingCell", forIndexPath: indexPath) as! LoadingCollectionViewCell
                cell.activityIndicator.startAnimating()
                loadNextCharacters()
                
                return cell
            } else { // Display character cell
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("characterCell", forIndexPath: indexPath) as! CharacterCollectionViewCell
                
                cell.configure(character: characters[indexPath.row])
                
                return cell
            }
        }
    }
}

extension CharacterListViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchText = searchController.searchBar.text!
        // TODO: Filter when going forward, discard search when going back.
        searchTextTimer?.invalidate()
        lastSearchText = searchText
        
        if searchText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) != "" {
            searching = true
            searchTextTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, repeats: false) { [weak self] (timer) in
                print("begin search for \(searchText)")
                self?.searching = true
                
                MarvelSDK.sharedInstance.characters(limit: 3, offset: 0, nameStartsWith: searchText, completionHandler: { (error, characters) in
                    if self?.lastSearchText == searchText {
                        print("done searching for \(searchText), display results")
                        self?.searching = false
                        
                        var newCharacters = characters
                        if let filtered = self?.filteredCharacters {
                            newCharacters.appendContentsOf(filtered)
                        }
                        
                        self?.filteredCharacters = newCharacters
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self?.collectionView.reloadData()
                        })
                    } else {
                        print("done searching for \(searchText) but results are no longer valid")
                    }
                })
            }
            
            filteredCharacters = MarvelSDK.sharedInstance.filteredCharactersFromCache(searchText: searchText)
        } else {
            searching = false
            filteredCharacters = nil
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.collectionView.reloadData()
        })
    }
}
