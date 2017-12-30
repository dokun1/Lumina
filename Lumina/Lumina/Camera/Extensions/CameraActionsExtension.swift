//
//  CameraActionsExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
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
        Log.info("Attempting photo capture")
        var settings = AVCapturePhotoSettings()
        if #available(iOS 11.0, *) {
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                Log.verbose("Will capture photo with HEVC codec")
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
        }
        settings.isAutoStillImageStabilizationEnabled = true
        switch self.torchState {
        //swiftlint:disable empty_enum_arguments
        case .on(_):
            settings.flashMode = .on
        case .off:
            settings.flashMode = .off
        case .auto:
            settings.flashMode = .auto
        }
        if self.captureLivePhotos {
            let fileName = NSTemporaryDirectory().appending("livePhoto" + Date().iso8601 + ".mov")
            settings.livePhotoMovieFileURL = URL(fileURLWithPath: fileName)
            Log.verbose("live photo filename will be \(fileName)")
        }
        if self.captureHighResolutionImages {
            settings.isHighResolutionPhotoEnabled = true
        }
        if #available(iOS 11.0, *) {
            if self.captureDepthData && self.photoOutput.isDepthDataDeliverySupported {
                Log.verbose("depth data delivery is enabled")
                settings.isDepthDataDeliveryEnabled = true
            }
        }
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func startVideoRecording() {
        Log.verbose("attempting to start video recording")
        if self.resolution == .photo {
            Log.error("Cannot start video recording - resolution is in .photo mode")
            return
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
            Log.verbose("will begin video recording with filename \(fileName)")
            self.videoFileOutput.startRecording(to: URL(fileURLWithPath: fileName), recordingDelegate: self)
        }
    }

    func stopVideoRecording() {
        Log.verbose("ending video recording")
        recordingVideo = false
        sessionQueue.async {
            self.videoFileOutput.stopRecording()
        }
    }
}
