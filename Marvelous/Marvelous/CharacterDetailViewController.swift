//
//  CharacterDetailViewController.swift
//  Marvelous
//
//  Created by Pablo Gomez Basanta on 10/31/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import Foundation
import UIKit
import MarvelSDK
import SDWebImage
import SafariServices

/// Displays all the details for a specified character.
class CharacterDetailViewController: UIViewController {
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var nameLabel:UILabel!
    @IBOutlet weak var descriptionTextView:UITextView!
    @IBOutlet weak var urlButton:UIButton!
    
    var character:MarvelCharacter?
    var detailURL:NSURL?
    
    override func viewWillAppear(animated: Bool) {
        configure()
    }
    
    /**
     Configures the view controller to display the details of the specified character.

     */
    func configure() {
        if let character = character {
            let smallImageURL = character.squareThumbURL()
            let detailImageURL = character.detailThumbURL()
            
            let manager = SDWebImageManager.sharedManager()
            var image:UIImage?
            let cacheKey = manager.cacheKeyForURL(smallImageURL)
            
            image = manager.imageCache.imageFromMemoryCacheForKey(cacheKey)
            if image == nil { // Try disk cache
                image = manager.imageCache.imageFromDiskCacheForKey(cacheKey)
            }
            
            imageView.sd_setImageWithURL(detailImageURL, placeholderImage: image)
            
            nameLabel.text = character.name
            descriptionTextView.text = character.desc
            
            navigationItem.title = character.name
            
            detailURL = character.detailURL()
            
            if detailURL == nil {
                urlButton.hidden = true
            } else {
                urlButton.hidden = false
            }
            
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "comicList" {
            let destination = segue.destinationViewController as! MarvelEntityListViewController
            
            destination.delegate = self
            destination.emptyStateText = "This character does not appear in any comics 😞"
            destination.fetchEntities = { [weak self] (limit, offset, completionHandler) in
                self?.character!.comics(limit: limit, offset: offset, completionHandler: { (error, comics) in
                    completionHandler(error: error, entities: comics)
                })
            }
        } else if segue.identifier == "seriesList" {
            let destination = segue.destinationViewController as! MarvelEntityListViewController
            
            destination.delegate = self
            destination.emptyStateText = "This character is not part of any series 😞"
            destination.fetchEntities = { [weak self] (limit, offset, completionHandler) in
                self?.character!.series(limit: limit, offset: offset, completionHandler: { (error, series) in
                    completionHandler(error: error, entities: series)
                })
            }
        } else if segue.identifier == "storyList" {
            let destination = segue.destinationViewController as! MarvelEntityListViewController
            
            destination.delegate = self
            destination.emptyStateText = "This character does not appear in any stories 😞"
            destination.fetchEntities = { [weak self] (limit, offset, completionHandler) in
                self?.character!.stories(limit: limit, offset: offset, completionHandler: { (error, stories) in
                    completionHandler(error: error, entities: stories)
                })
            }
        } else if segue.identifier == "eventList" {
            let destination = segue.destinationViewController as! MarvelEntityListViewController
            
            destination.delegate = self
            destination.emptyStateText = "This character is not part of any events 😞"
            destination.fetchEntities = { [weak self] (limit, offset, completionHandler) in
                self?.character!.events(limit: limit, offset: offset, completionHandler: { (error, events) in
                    completionHandler(error: error, entities: events)
                })
            }
        }
    }
    /**
     Opens the Marvel.com url for the character in a `SFSafariViewController`.
     
     - Parameter sender: The button that initiated the event.
     */
    @IBAction func openURL(sender: UIButton) {
        if let url = detailURL {
            let safariViewController = SFSafariViewController(URL: url)
            presentViewController(safariViewController, animated: true, completion: nil)
        }
    }
}

extension CharacterDetailViewController: MarvelEntitiyListViewControllerDelegate {
    func didSelectEntity(entity: MarvelEntity) {
        if let url = entity.detailURL() {
            let safariViewController = SFSafariViewController(URL: url)
            presentViewController(safariViewController, animated: true, completion: nil)
        }
    }
}
