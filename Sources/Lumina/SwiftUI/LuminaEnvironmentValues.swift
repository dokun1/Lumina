//
//  LuminaEnvironmentValues.swift
//  Lumina
//
//  Created by Claude on 2026-01-25.
//  Copyright © 2026 David Okun. All rights reserved.
//

import SwiftUI
import CoreML
import Logging

// MARK: - Camera Configuration Environment Values

extension EnvironmentValues {
    /// The position of the camera (front or back)
    @Entry var luminaCameraPosition: CameraPosition = .back

    /// Whether the camera should record video
    @Entry var luminaRecordsVideo: Bool = false

    /// Whether the camera should stream video frames
    @Entry var luminaStreamFrames: Bool = false

    /// Whether the camera should track metadata (QR codes, barcodes, faces)
    @Entry var luminaTrackMetadata: Bool = false

    /// The text prompt displayed to the user
    @Entry var luminaTextPrompt: String = ""

    /// The camera resolution
    @Entry var luminaResolution: CameraResolution = .highest

    /// The camera frame rate
    @Entry var luminaFrameRate: Int = 30

    /// Whether to capture live photos
    @Entry var luminaCaptureLivePhotos: Bool = false

    /// Whether to capture depth data with still images
    @Entry var luminaCaptureDepthData: Bool = false

    /// Whether to stream depth data with video frames
    @Entry var luminaStreamDepthData: Bool = false

    /// The maximum zoom scale
    @Entry var luminaMaxZoomScale: Float = .greatestFiniteMagnitude

    /// The current zoom scale
    @Entry var luminaCurrentZoomScale: Float = 1.0

    /// CoreML models for streaming object recognition
    @Entry var luminaStreamingModels: [LuminaModel]? = nil

    /// The torch/flash state
    @Entry var luminaTorchState: TorchState = .off
}

// MARK: - Button Visibility Environment Values

extension EnvironmentValues {
    /// Whether the cancel button is visible
    @Entry var luminaCancelButtonVisible: Bool = true

    /// Whether the shutter button is visible
    @Entry var luminaShutterButtonVisible: Bool = true

    /// Whether the camera switch button is visible
    @Entry var luminaSwitchButtonVisible: Bool = true

    /// Whether the torch button is visible
    @Entry var luminaTorchButtonVisible: Bool = true
}

// MARK: - Event Handler Environment Values

/// A container for Lumina event handlers
public struct LuminaEventHandlers: Sendable {
    public var onStillImageCaptured: (@Sendable (UIImage, URL?, Any?) -> Void)?
    public var onVideoCaptured: (@Sendable (URL) -> Void)?
    public var onVideoFrameStreamed: (@Sendable (UIImage) -> Void)?
    public var onVideoFrameWithPredictions: (@Sendable (UIImage, [LuminaRecognitionResult]?) -> Void)?
    public var onDepthDataStreamed: (@Sendable (Any) -> Void)?
    public var onMetadataDetected: (@Sendable ([Any]) -> Void)?
    public var onDismissed: (@Sendable () -> Void)?
    public var onTapped: (@Sendable (CGPoint) -> Void)?

    public init(
        onStillImageCaptured: (@Sendable (UIImage, URL?, Any?) -> Void)? = nil,
        onVideoCaptured: (@Sendable (URL) -> Void)? = nil,
        onVideoFrameStreamed: (@Sendable (UIImage) -> Void)? = nil,
        onVideoFrameWithPredictions: (@Sendable (UIImage, [LuminaRecognitionResult]?) -> Void)? = nil,
        onDepthDataStreamed: (@Sendable (Any) -> Void)? = nil,
        onMetadataDetected: (@Sendable ([Any]) -> Void)? = nil,
        onDismissed: (@Sendable () -> Void)? = nil,
        onTapped: (@Sendable (CGPoint) -> Void)? = nil
    ) {
        self.onStillImageCaptured = onStillImageCaptured
        self.onVideoCaptured = onVideoCaptured
        self.onVideoFrameStreamed = onVideoFrameStreamed
        self.onVideoFrameWithPredictions = onVideoFrameWithPredictions
        self.onDepthDataStreamed = onDepthDataStreamed
        self.onMetadataDetected = onMetadataDetected
        self.onDismissed = onDismissed
        self.onTapped = onTapped
    }
}

extension EnvironmentValues {
    /// Event handlers for Lumina camera events
    @Entry var luminaEventHandlers: LuminaEventHandlers = LuminaEventHandlers()
}
