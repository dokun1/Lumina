//
//  ImageViewController.swift
//  LuminaSample
//
//  Created by David Okun on 9/25/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    @IBOutlet public weak var imageView: UIImageView!
    
    var image: UIImage?
    
    override func viewWillAppear(_ animated: Bool) {
        self.imageView.image = self.image
    }
}
