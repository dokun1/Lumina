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
            if let modelPairs = self.streamingModels {
                LuminaLogger.notice(message: "valid CoreML models present - attempting to scan photo")
                if self.recognizer == nil {
                    let newRecognizer = LuminaObjectRecognizer(modelPairs: modelPairs)
                    self.recognizer = newRecognizer
                }
                guard let recognizer = self.recognizer as? LuminaObjectRecognizer else {
                    LuminaLogger.error(message: "models loaded, but could not use object recognizer")
                    DispatchQueue.main.async {
                        self.delegate?.videoFrameCaptured(camera: self, frame: image)
                    }
                    return
                }
                recognizer.recognize(from: image, completion: { results in
                    DispatchQueue.main.async {
                        self.delegate?.videoFrameCaptured(camera: self, frame: image, predictedObjects: results)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    self.delegate?.videoFrameCaptured(camera: self, frame: image)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.videoFrameCaptured(camera: self, frame: image)
            }
        }
    }
}
