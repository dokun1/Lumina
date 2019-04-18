//
//  LuminaPhotoCapture.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

struct LuminaPhotoCapture {
    var camera: LuminaCamera?

    var stillImage: UIImage? {
        didSet {
            collectionUpdated()
        }
    }

    var livePhotoURL: URL? {
        didSet {
            collectionUpdated()
        }
    }

    private var _depthData: Any?
    @available(iOS 11.0, *)
    var depthData: AVDepthData? {
        get {
            return _depthData as? AVDepthData
        }
        set {
            if newValue != nil {
                _depthData = newValue
                collectionUpdated()
            }
        }
    }

    fileprivate func collectionUpdated() {
        LuminaLogger.notice(message: "photo capture struct updating")
        var sendingLivePhotoURL: URL?
        var sendingDepthData: Any?
        guard let sendingCamera = camera, let image = stillImage else {
            return
        }
        if sendingCamera.captureLivePhotos == true {
            if let url = livePhotoURL {
                LuminaLogger.notice(message: "new live photo added to current capture struct at \(url.absoluteString)")
                sendingLivePhotoURL = url
            } else {
                return
            }
        }

        if sendingCamera.captureDepthData == true, #available(iOS 11.0, *) {
            if let data = depthData {
                LuminaLogger.notice(message: "new depth data map added to current capture struct")
                sendingDepthData = data
            } else {
                return
            }
        }
        DispatchQueue.main.async {
            LuminaLogger.info(message: "still image has been captured")
            sendingCamera.delegate?.stillImageCaptured(camera: sendingCamera, image: image, livePhotoURL: sendingLivePhotoURL, depthData: sendingDepthData)
        }
    }
}
