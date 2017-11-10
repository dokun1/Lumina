//
//  ImageViewController.swift
//  LuminaSample
//
//  Created by David Okun on 9/25/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import AVKit
import Lumina

class ImageViewController: UIViewController {
    @IBOutlet public weak var imageView: UIImageView!
    @IBOutlet public weak var livePhotoButton: UIBarButtonItem!
    @IBOutlet public weak var depthDataButton: UIBarButtonItem!
    
    var image: UIImage?
    var livePhotoURL: URL?
    var showingDepth: Bool = false
    var position: CameraPosition = .back
    private var _depthData: Any?
    
    @available(iOS 11.0, *)
    var depthData: AVDepthData? {
        get {
            return _depthData as? AVDepthData
        }
        set {
            if newValue != nil {
                _depthData = newValue
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.imageView.image = self.image
        if livePhotoURL != nil {
            self.livePhotoButton.isEnabled = true
        }
        if #available(iOS 11.0, *) {
            if depthData != nil {
                self.depthDataButton.isEnabled = true
            }
        }
        
    }
    
    @IBAction func livePhotoButtonTapped() {
        if let url = livePhotoURL {
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        }
    }
    
    @IBAction func depthDataButtonTapped() {
        if #available(iOS 11.0, *) {
            if let data = depthData {
                if self.showingDepth == false {
                    if let map = data.depthDataMap.normalizedImage(with: self.position) {
                        self.imageView.image = map
                    } else {
                        self.showingDepth = true
                    }
                } else {
                    self.imageView.image = self.image
                }
                self.showingDepth = !self.showingDepth
            }
        }
    }
}
