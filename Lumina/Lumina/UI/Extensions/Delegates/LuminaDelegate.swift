//
//  LuminaDelegate.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import CoreML

/// Delegate for returning information to the application utilizing Lumina
public protocol LuminaDelegate: class {

    /// Triggered whenever a still image is captured by the user of Lumina
    ///
    /// - Parameters:
    ///   - stillImage: the image captured by Lumina
    ///   - livePhotoAt: the URL where the live photo file can be located and used, if enabled and available
    ///   - depthData: the depth data associated with the captured still image, if enabled and available (iOS 11.0 only)
    ///   - controller: the instance of Lumina that captured the still image
    func captured(stillImage: UIImage, livePhotoAt: URL?, depthData: Any?, from controller: LuminaViewController)

    /// Triggered whenever a video is captured by the user of Lumina
    ///
    /// - Parameters:
    ///   - videoAt: the URL where the video file can be located and used
    ///   - controller: the instance of Lumina that captured the still image
    func captured(videoAt: URL, from controller: LuminaViewController)

    /// Triggered whenever streamFrames is set to true on Lumina, and streams video frames as UIImage instances
    ///
    /// - Note: Will not be triggered unless streamFrames is true. False is default value
    /// - Parameters:
    ///   - videoFrame: the frame captured by Lumina
    ///   - controller: the instance of Lumina that is streaming the frames
    func streamed(videoFrame: UIImage, from controller: LuminaViewController)

    /// Triggered whenever a collection of CoreML models is given to Lumina, and Lumina streams a video frame alongside a collection of predictions
    ///
    /// - Note: Will not be triggered unless streamingModel resolves to not nil. Leaving the streamingModel parameter unset will not trigger this method
    /// - Warning: The other method for passing video frames back via a delegate will not be triggered in the presence of a CoreML model
    /// - Parameters:
    ///   - videoFrame: the frame captured by Lumina
    ///   - predictions: an array of objects typed LuminaRecognitionResult, containing the predictions made by a model used with Lumina, and its type, for matching against when parsing results.
    ///   - controller: the instance of Lumina that is streaming the frames
    func streamed(videoFrame: UIImage, with predictions: [LuminaRecognitionResult]?, from controller: LuminaViewController)

    /// Triggered whenever streamDepthData is set to true on Lumina, and streams depth data detected in the form of AVDepthData
    ///
    /// - Warning: This data is returned from type `Any`, and must be optionally downcast to `AVDepthData` by the user of Lumina. This is to maintain backwards compatibility with iOS 10.0
    /// - Note: This is only available on iOS 11.0
    /// - Parameters:
    ///   - depthData: buffer containing AVDepthData relevant to the streamed video frame
    ///   - controller: the instance of Lumina that is streaming the depth data
    func streamed(depthData: Any, from controller: LuminaViewController)

    /// Triggered whenever trackMetadata is set to true on Lumina, and streams metadata detected in the form of QR codes, bar codes, or faces
    ///
    /// - Note: For list of all machine readable object types, aside from QR codes or faces, click [here](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject/machine_readable_object_types).
    ///
    /// - Warning: Objects returned in array must be casted to AVMetadataObject or AVMetadataFaceObject individually.
    ///
    /// - Parameters:
    ///   - metadata: the array of metadata that is captured.
    ///   - controller: the instance of Lumina that is streaming the metadata
    func detected(metadata: [Any], from controller: LuminaViewController)

    /// Triggered whenever the cancel button is tapped on Lumina, with the intent of dismissing the UIViewController
    ///
    /// - Note: This is most usually used whenever
    ///
    /// - Parameter controller: the instance of Lumina that cancel was tapped on
    func dismissed(controller: LuminaViewController)

    /// Triggered whenever the image is tapped (outside of the buttons)
    ///
    // swiftlint:disable identifier_name
    func tapped(at: CGPoint, from controller: LuminaViewController)
}

// MARK: Extension to make delegate functions optional

public extension LuminaDelegate {
    func captured(stillImage: UIImage, livePhotoAt: URL?, depthData: Any?, from controller: LuminaViewController) {}
    func captured(videoAt: URL, from controller: LuminaViewController) {}
    func streamed(videoFrame: UIImage, from controller: LuminaViewController) {}
    func streamed(videoFrame: UIImage, with predictions: [LuminaRecognitionResult]?, from controller: LuminaViewController) {}
    func streamed(depthData: Any, from controller: LuminaViewController) {}
    func detected(metadata: [Any], from controller: LuminaViewController) {}
    func dismissed(controller: LuminaViewController) {}
    func tapped(at: CGPoint, from controller: LuminaViewController) {}
}
