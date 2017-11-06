//
//  ImageViewController.swift
//  LuminaSample
//
//  Created by David Okun on 9/25/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import AVKit

class ImageViewController: UIViewController {
    @IBOutlet public weak var imageView: UIImageView!
    @IBOutlet public weak var livePhotoButton: UIBarButtonItem!
    @IBOutlet public weak var depthDataButton: UIBarButtonItem!
    
    var image: UIImage?
    var livePhotoURL: URL?
    var showingDepth: Bool = false
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
                    if let map = getImage(from: data.depthDataMap) {
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
    
    private func getImage(from depthDataMap: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: depthDataMap)
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(depthDataMap), height: CVPixelBufferGetHeight(depthDataMap))) {
            return cgImage.normalizedImage()
        } else {
            return nil
        }
    }
}

private extension CGImage {
    func normalizedImage() -> UIImage? {
        return UIImage(cgImage: self , scale: 1.0, orientation: getImageOrientation())
    }
    
    private func getImageOrientation() -> UIImageOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            return .down
        case .landscapeRight:
            return .up
        case .portraitUpsideDown:
            return .left
        case .portrait:
            return .right
        case .unknown:
            return .right
        }
    }
}
