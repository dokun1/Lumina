//
//  LuminaCamera+FileOutputRecordingDelegate.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension LuminaCamera: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            if error == nil, let delegate = self.delegate {
                delegate.videoRecordingCaptured(camera: self, videoURL: outputFileURL)
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if self.captureLivePhotos {
            LuminaLogger.notice(message: "beginning live photo capture")
            self.delegate?.cameraBeganTakingLivePhoto(camera: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if self.captureLivePhotos {
            LuminaLogger.notice(message: "finishing live photo capture")
            self.delegate?.cameraFinishedTakingLivePhoto(camera: self)
        }
    }

    //swiftlint:disable function_parameter_count
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        photoCollectionQueue.sync {
            if self.currentPhotoCollection == nil {
                var collection = LuminaPhotoCapture()
                collection.camera = self
                collection.livePhotoURL = outputFileURL
                self.currentPhotoCollection = collection
            } else {
                guard var collection = self.currentPhotoCollection else {
                    return
                }
                collection.camera = self
                collection.livePhotoURL = outputFileURL
                self.currentPhotoCollection = collection
            }
        }
    }
}
