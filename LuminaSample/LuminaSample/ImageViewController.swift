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

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    let doubleTap = UITapGestureRecognizer()
    
    @IBOutlet public weak var imageView: UIImageView!
    @IBOutlet public weak var livePhotoButton: UIBarButtonItem!
    @IBOutlet public weak var depthDataButton: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!
    
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
        //Scrollview setup.
        scrollView.delegate = self
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0//maximum zoom scale you want
        scrollView.zoomScale = 1.0
        
        //Tap gesture recognizer setup.
        doubleTap.numberOfTapsRequired = 2
        doubleTap.addTarget(self, action: #selector(ImageViewController.ZoomInOnPhoto))
        scrollView.addGestureRecognizer(doubleTap)
        
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
    
    //MARK: - Scrollview functionality.
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    //END OF SCROLLVIEW FUNCTIONALITY
    
    //MARK: - Tap to zoom functionality.
    @objc func ZoomInOnPhoto(recognizer: UITapGestureRecognizer){
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: 2, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    //END OF TAP TO ZOOM FUNCTIONALITY
    
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
