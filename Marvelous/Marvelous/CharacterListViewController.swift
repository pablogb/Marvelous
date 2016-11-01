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
    let limit = 30
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
    
    // Layout
    var cellSize:CGFloat = 150.0
    
    // Keyboard layout
    var bottomConstraintConstant:CGFloat = 0.0
    @IBOutlet weak var scrollViewBottomConstraint:NSLayoutConstraint!
    
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
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(CharacterListViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(CharacterListViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification:NSNotification) {
        let info = notification.userInfo
        var keyboardRect = (info?[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        keyboardRect = view.convertRect(keyboardRect, fromView: nil)
        
        var newConstant = bottomConstraintConstant + keyboardRect.size.height
        
        if let tabBarController = self.tabBarController {
            newConstant -= tabBarController.tabBar.bounds.height
        }
        
        if newConstant != scrollViewBottomConstraint.constant {
            scrollViewBottomConstraint.constant = newConstant
            
            let animationDuration = (info?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue as NSTimeInterval
            let animationCurve = UIViewAnimationCurve(rawValue: (info?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue)
            
            UIView.animateWithDuration(animationDuration, delay: 0.0, options: animationCurve!.toOptions(), animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
    }
    
    func keyboardWillHide(notification:NSNotification) {
        if scrollViewBottomConstraint.constant != bottomConstraintConstant {
            scrollViewBottomConstraint.constant = bottomConstraintConstant
            
            let info = notification.userInfo
            let animationDuration = (info?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue as NSTimeInterval
            let animationCurve = UIViewAnimationCurve(rawValue: (info?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue)
            
            UIView.animateWithDuration(animationDuration, delay: 0.0, options: animationCurve!.toOptions(), animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showCharacterDetail" {
            let character = sender as? MarvelCharacter
            let destination = segue.destinationViewController as! CharacterDetailViewController
            
            destination.character = character
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        searchController.searchBar.sizeToFit()
        
        // Calculate best cell size for view width. 
        
        
        
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let s = flowLayout.minimumInteritemSpacing // Inter cell spacing
        let x = collectionView.bounds.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right // Useable width
        let w = CGFloat(150.0) // Target cell width (minimum)
        
        let n = floor((x+s)/(w+s)) // Number of cells we can fit on the screen, given by w*n + s*(n-1) = x
        
        let nw = floor((x-s*(n-1))/n) // This is the width we need to fit n cells in the screen according to the same formula.
        
        if nw != cellSize {
            cellSize = nw
            dispatch_async(dispatch_get_main_queue(), { 
                self.collectionView.collectionViewLayout.invalidateLayout()
            })
        }
    }
    
    func loadNextCharacters() {
        if loadingNext == false {
            loadingNext = true
            
            MarvelSDK.sharedInstance.characters(limit: limit, offset: offset, nameStartsWith: nil) { [weak self] (error, characters) in
                if let vc = self {
                    if characters.count == vc.limit { vc.moreCharacters = true }
                    else { vc.moreCharacters = false }
                    
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

extension CharacterListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
        } else {
            if searching {  // Return Searching cell.
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("searchingCell", forIndexPath: indexPath) as! LoadingCollectionViewCell
                cell.activityIndicator.startAnimating()
                
                return cell
            } else {  // Return Loading cell.
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("loadingCell", forIndexPath: indexPath) as! LoadingCollectionViewCell
                cell.activityIndicator.startAnimating()
                
                loadNextCharacters()
                
                return cell
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if searching && indexPath.row == 0 {
            let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            let usableWidth = collectionView.bounds.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right // Useable width
            
            return CGSize(width: usableWidth, height: 60.0)
        }
        
        return CGSize(width: cellSize, height: cellSize)
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
                    self?.searching = true
                    
                    MarvelSDK.sharedInstance.characters(limit: self?.searchLimit, offset: 0, nameStartsWith: searchText, completionHandler: { (error, characters) in
                        if self?.lastSearchText == searchText {
                            self?.searching = false
                            
                            self?.searchResultString = searchText
                            self?.searchResultCharacters = characters
                            
                            self?.updatedFilteredCharacters()
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                self?.collectionView.reloadData()
                            })
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
