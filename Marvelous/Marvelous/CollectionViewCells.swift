//
//  CollectionViewCells.swift
//  Marvelous
//
//  Created by Pablo Gomez Basanta on 10/30/16.
//  Copyright © 2016 Shifting Mind. All rights reserved.
//

import UIKit
import SDWebImage
import MarvelSDK

class CharacterCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var nameLabel:UILabel!
    
    func configure(character character:MarvelCharacter) {
        nameLabel.text = character.name
        imageView.sd_setImageWithURL(character.squareThumbURL())
    }
}

class LoadingCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var activityIndicator:UIActivityIndicatorView!
}
