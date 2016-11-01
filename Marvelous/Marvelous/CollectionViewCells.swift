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

class EntityCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var nameLabel:UILabel!
    
    func configure(entity entity:MarvelEntity) {
        nameLabel.text = entity.name
        imageView.sd_setImageWithURL(entity.squareThumbURL())
    }
}

class LoadingCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var activityIndicator:UIActivityIndicatorView!
}
