//
//  PhotoCaptureDelegateExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension LuminaCamera: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    LuminaLogger.notice(message: "finished processing photo")
    guard let image = photo.normalizedImage(forCameraPosition: self.position) else {
      return
    }
    photoCollectionQueue.sync {
      if self.currentPhotoCollection == nil {
        var collection = LuminaPhotoCapture()
        collection.camera = self
        collection.depthData = photo.depthData
        collection.stillImage = image
        self.currentPhotoCollection = collection
      } else {
        guard var collection = self.currentPhotoCollection else {
          return
        }
        collection.camera = self
        collection.depthData = photo.depthData
        collection.stillImage = image
        self.currentPhotoCollection = collection
      }
    }
  }
}
