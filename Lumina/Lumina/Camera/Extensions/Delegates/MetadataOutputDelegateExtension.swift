//
//  MetadataOutputDelegateExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension LuminaCamera: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        LuminaLogger.notice(message: "metadata detected - \(metadataObjects)")
        guard case self.trackMetadata = true else {
            return
        }
        DispatchQueue.main.async {
            self.delegate?.detected(camera: self, metadata: metadataObjects)
        }
    }
}
