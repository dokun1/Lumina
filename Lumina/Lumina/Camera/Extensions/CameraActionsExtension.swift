//
//  CameraActionsExtension.swift
//  Lumina
//
//  Created by David Okun IBM on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension LuminaCamera {
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return previewLayer
    }
    
    func captureStillImage() {
        var settings = AVCapturePhotoSettings()
        if #available(iOS 11.0, *) {
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
        }
        settings.isAutoStillImageStabilizationEnabled = true
        settings.flashMode = self.torchState ? .on : .off
        if self.captureLivePhotos {
            let fileName = NSTemporaryDirectory().appending("livePhoto" + Date().iso8601 + ".mov")
            settings.livePhotoMovieFileURL = URL(fileURLWithPath: fileName)
        }
        if self.captureHighResolutionImages {
            settings.isHighResolutionPhotoEnabled = true
        }
        if #available(iOS 11.0, *) {
            if self.captureDepthData && self.photoOutput.isDepthDataDeliverySupported {
                settings.isDepthDataDeliveryEnabled = true
            }
        }
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startVideoRecording() {
        if self.resolution == .photo {
            return // TODO: make this function throw an error
        }
        recordingVideo = true
        sessionQueue.async {
            if let connection = self.videoFileOutput.connection(with: AVMediaType.video), let videoConnection = self.videoDataOutput.connection(with: AVMediaType.video) {
                connection.videoOrientation = videoConnection.videoOrientation
                connection.isVideoMirrored = self.position == .front ? true : false
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .cinematic
                }
                self.session.commitConfiguration()
            }
            let fileName = NSTemporaryDirectory().appending(Date().iso8601 + ".mov")
            self.videoFileOutput.startRecording(to: URL(fileURLWithPath: fileName), recordingDelegate: self)
        }
    }
    
    func stopVideoRecording() {
        recordingVideo = false
        sessionQueue.async {
            self.videoFileOutput.stopRecording()
        }
    }
}
