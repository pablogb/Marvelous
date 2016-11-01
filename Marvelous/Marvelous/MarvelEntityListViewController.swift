//
//  MarvelEntityListViewController.swift
//  Marvelous
//
//  Created by Pablo Gomez Basanta on 10/31/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import Foundation
import UIKit
import MarvelSDK

typealias EntityFetchCallback = ((error:MarvelSDKError?, entities:[MarvelEntity]) -> Void)

/// This protocol allows MarvelEntityListViewController to notify an object when one of its cells is tapped.
protocol MarvelEntitiyListViewControllerDelegate: class {
    func didSelectEntity(entity:MarvelEntity)
}

/// Displays a list of entities in a collection view.
class MarvelEntityListViewController: UICollectionViewController {
    var entities:[MarvelEntity] = []
    
    weak var delegate:MarvelEntitiyListViewControllerDelegate?
    
    var fetchEntities:((limit:Int, offset:Int, completionHandler:EntityFetchCallback) -> Void)?
    
    var backgroundLabel:UILabel!
    var emptyStateText:String = "There are no objects in this collection."
    
    // Paging
    let limit = 20
    var offset = 0
    var moreEntities = true
    var loadingNext = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundLabel = UILabel()
        backgroundLabel.textColor = UIColor.whiteColor()
        backgroundLabel.textAlignment = .Center
        backgroundLabel.numberOfLines = 0
        backgroundLabel.minimumScaleFactor = 0.6
        backgroundLabel.font = UIFont.boldSystemFontOfSize(20.0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        backgroundLabel.text = emptyStateText
    }
    
    /// Retrieves and displays the the next page of entities from the API. 
    func loadNextEntities() {
        if loadingNext == false {
            loadingNext = true
            
            fetchEntities?(limit: limit, offset: offset) { [weak self] (error, entities) in
                if let vc = self {
                    if let error = error {
                        let message:String?
                        switch(error) {
                            case .NoResponse: message = "Could not establish connection with the server. Please check your internet connection and try again."
                            case .RateLimitReached: message = "The API rate limit was reached. Please try again later."
                            case .InternalError: message = "An unexpected error ocurred. Please try again later."
                        }
                        
                        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                        self?.presentViewController(alertController, animated: true, completion: nil)
                    } else {
                        if entities.count == vc.limit { vc.moreEntities = true }
                        else { vc.moreEntities = false }
                        
                        vc.offset += vc.limit
                        
                        let oldCount = vc.entities.count
                        
                        vc.entities.appendContentsOf(entities)
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            var indexPaths:[NSIndexPath] = []
                            
                            for (index, _) in entities.enumerate() {
                                indexPaths.append(NSIndexPath(forRow: oldCount + index, inSection: 0))
                            }
                            
                            if vc.moreEntities == false {
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
                    }
                    
                    vc.loadingNext = false
                }
            }
        }
    }
}

extension MarvelEntityListViewController { // UICollectionViewDelegate, UICollectionViewDataSource
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if moreEntities { return entities.count + 1 }
        else {
            if entities.count == 0 {
                collectionView.backgroundView = backgroundLabel
                backgroundLabel.sizeToFit()
            } else {
                collectionView.backgroundView = nil
            }
            
            return entities.count
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let entity = entityFor(indexPath: indexPath)
        if let entity = entity {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("entityCell", forIndexPath: indexPath) as! EntityCollectionViewCell
            
            cell.configure(entity: entity)
            
            return cell
        } else { // Return Loading cell.
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("loadingCell", forIndexPath: indexPath) as! LoadingCollectionViewCell
            cell.activityIndicator.startAnimating()
            
            loadNextEntities()
            
            return cell
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        if let entity = entityFor(indexPath: indexPath) {
            delegate?.didSelectEntity(entity)
        }
    
    }
    /**
     Returns the entity corresponding to the specified `indexPath`
     
     - Parameter indexPath: An indexPath for the `collectionView`
     
     - Returns: The entity associated to that `indexPath` or nil if there is no entity for that `indexPath`.
     */
    func entityFor(indexPath indexPath:NSIndexPath) -> MarvelEntity? {
        if indexPath.row == entities.count { // Display loading cell.
            return nil
        } else { // Display entitiy cell
            return entities[indexPath.row]
        }
    }
}
