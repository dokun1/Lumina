//
//  SampleBufferExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension CMSampleBuffer {
    func normalizedStillImage(forCameraPosition position: CameraPosition) -> UIImage? {
        LuminaLogger.notice(message: "normalizing still image from CMSampleBuffer")
        // 'jpegPhotoDataRepresentation(forJPEGSampleBuffer:previewPhotoSampleBuffer:)' was deprecated in iOS 11.0: Use -[AVCapturePhoto fileDataRepresentation] instead.
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: self, previewPhotoSampleBuffer: nil) else {
            return nil
        }
        guard let dataProvider = CGDataProvider(data: imageData as CFData) else {
            return nil
        }
        guard let cgImageRef = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent) else {
            return nil
        }
        return UIImage(cgImage: cgImageRef, scale: 1.0, orientation: getImageOrientation(forCamera: position))
    }

    func normalizedVideoFrame() -> UIImage? {
        LuminaLogger.notice(message: "normalizing video frame from CMSampleBbuffer")
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
            return nil
        }
        let coreImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let context: CIContext = CIContext()
        guard let sample: CGImage = context.createCGImage(coreImage, from: coreImage.extent) else {
            return nil
        }
        return UIImage(cgImage: sample)
    }

    private func getImageOrientation(forCamera: CameraPosition) -> UIImage.Orientation {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            return forCamera == .back ? .down : .upMirrored
        case .landscapeRight:
            return forCamera == .back ? .up : .downMirrored
        case .portraitUpsideDown:
            return forCamera == .back ? .left : .rightMirrored
        case .portrait:
            return forCamera == .back ? .right : .leftMirrored
        case .unknown:
            return forCamera == .back ? .right : .leftMirrored
        @unknown default:
            return forCamera == .back ? .right : .leftMirrored
        }
    }
}
