//
//  DepthDataExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

@available(iOS 11.0, *)
extension LuminaCamera: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            self.delegate?.depthDataCaptured(camera: self, depthData: depthData)
        }
    }

    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didDrop depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection, reason: AVCaptureOutput.DataDroppedReason) {
        LuminaLogger.error(message: "dropped depth data output")
    }
}
