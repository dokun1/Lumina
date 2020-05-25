//
//  CameraActions.swift
//
//  Created by David Okun on 5/25/20.
//

import Foundation
import AVFoundation

extension Lumina.Camera {
  func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
    let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    return previewLayer
  }
}
