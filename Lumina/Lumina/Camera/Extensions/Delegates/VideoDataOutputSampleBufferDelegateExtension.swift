//
//  VideoDataOutputSampleBufferDelegate.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension LuminaCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = sampleBuffer.normalizedVideoFrame() else {
            return
        }
        if #available(iOS 11.0, *) {
            guard let recognizer = self.recognizer as? LuminaObjectRecognizer else {
                DispatchQueue.main.async {
                    self.delegate?.videoFrameCaptured(camera: self, frame: image)
                }
                return
            }
            recognizer.recognize(from: image, completion: { predictions in
                DispatchQueue.main.async {
                    self.delegate?.videoFrameCaptured(camera: self, frame: image, predictedObjects: predictions)
                }
            })
        } else {
            DispatchQueue.main.async {
                self.delegate?.videoFrameCaptured(camera: self, frame: image)
            }
        }
    }
}
