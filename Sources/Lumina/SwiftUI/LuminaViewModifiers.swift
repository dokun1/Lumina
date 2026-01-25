//
//  LuminaViewModifiers.swift
//  Lumina
//
//  Created by Claude on 2026-01-25.
//  Copyright © 2026 David Okun. All rights reserved.
//

import SwiftUI

// MARK: - Camera Configuration Modifiers

public extension View {
    /// Sets the camera position (front or back).
    ///
    /// - Parameter position: The camera position to use.
    /// - Returns: A view with the camera position configured.
    func luminaCameraPosition(_ position: CameraPosition) -> some View {
        environment(\.luminaCameraPosition, position)
    }

    /// Enables or disables video recording mode.
    ///
    /// When enabled, long-pressing the shutter button will record video.
    ///
    /// - Warning: When video recording is enabled, frame streaming and CoreML recognition are disabled.
    /// - Parameter enabled: Whether video recording is enabled.
    /// - Returns: A view with video recording configured.
    func luminaRecordsVideo(_ enabled: Bool) -> some View {
        environment(\.luminaRecordsVideo, enabled)
    }

    /// Enables or disables video frame streaming.
    ///
    /// When enabled, video frames are streamed through the `luminaOnVideoFrameStreamed` handler.
    ///
    /// - Parameter enabled: Whether frame streaming is enabled.
    /// - Returns: A view with frame streaming configured.
    func luminaStreamFrames(_ enabled: Bool) -> some View {
        environment(\.luminaStreamFrames, enabled)
    }

    /// Enables or disables metadata tracking (QR codes, barcodes, faces).
    ///
    /// When enabled, detected metadata is streamed through the `luminaOnMetadataDetected` handler.
    ///
    /// - Parameter enabled: Whether metadata tracking is enabled.
    /// - Returns: A view with metadata tracking configured.
    func luminaTrackMetadata(_ enabled: Bool) -> some View {
        environment(\.luminaTrackMetadata, enabled)
    }

    /// Sets the text prompt displayed to the user.
    ///
    /// Use this to provide instructions or context to the user while the camera is active.
    ///
    /// - Parameter text: The text to display. Pass an empty string to hide the prompt.
    /// - Returns: A view with the text prompt configured.
    func luminaTextPrompt(_ text: String) -> some View {
        environment(\.luminaTextPrompt, text)
    }

    /// Sets the camera resolution.
    ///
    /// - Parameter resolution: The desired camera resolution.
    /// - Returns: A view with the resolution configured.
    func luminaResolution(_ resolution: CameraResolution) -> some View {
        environment(\.luminaResolution, resolution)
    }

    /// Sets the camera frame rate.
    ///
    /// - Parameter frameRate: The desired frame rate in frames per second.
    /// - Returns: A view with the frame rate configured.
    func luminaFrameRate(_ frameRate: Int) -> some View {
        environment(\.luminaFrameRate, frameRate)
    }

    /// Enables or disables live photo capture.
    ///
    /// When enabled, live photos are captured alongside still images.
    ///
    /// - Note: This overrides the camera resolution to `.photo`.
    /// - Warning: Live photos are not available when video recording is enabled.
    /// - Parameter enabled: Whether live photo capture is enabled.
    /// - Returns: A view with live photo capture configured.
    func luminaCaptureLivePhotos(_ enabled: Bool) -> some View {
        environment(\.luminaCaptureLivePhotos, enabled)
    }

    /// Enables or disables depth data capture with still images.
    ///
    /// - Note: Only works with `.photo`, `.medium1280x720`, and `.vga640x480` resolutions.
    /// - Parameter enabled: Whether depth data capture is enabled.
    /// - Returns: A view with depth data capture configured.
    func luminaCaptureDepthData(_ enabled: Bool) -> some View {
        environment(\.luminaCaptureDepthData, enabled)
    }

    /// Enables or disables depth data streaming with video frames.
    ///
    /// - Note: Only works with `.photo`, `.medium1280x720`, and `.vga640x480` resolutions.
    /// - Parameter enabled: Whether depth data streaming is enabled.
    /// - Returns: A view with depth data streaming configured.
    func luminaStreamDepthData(_ enabled: Bool) -> some View {
        environment(\.luminaStreamDepthData, enabled)
    }

    /// Sets the maximum zoom scale.
    ///
    /// - Parameter scale: The maximum zoom scale. Use `.greatestFiniteMagnitude` for device maximum.
    /// - Returns: A view with the maximum zoom scale configured.
    func luminaMaxZoomScale(_ scale: Float) -> some View {
        environment(\.luminaMaxZoomScale, scale)
    }

    /// Sets the current zoom scale.
    ///
    /// - Parameter scale: The current zoom scale (1.0 is no zoom).
    /// - Returns: A view with the current zoom scale configured.
    func luminaCurrentZoomScale(_ scale: Float) -> some View {
        environment(\.luminaCurrentZoomScale, scale)
    }

    /// Sets the CoreML models for streaming object recognition.
    ///
    /// When models are provided, video frames are processed through CoreML and results
    /// are streamed through the `luminaOnVideoFrameWithPredictions` handler.
    ///
    /// - Warning: Setting streaming models automatically enables frame streaming.
    /// - Parameter models: An array of `LuminaModel` instances, or `nil` to disable recognition.
    /// - Returns: A view with streaming models configured.
    func luminaStreamingModels(_ models: [LuminaModel]?) -> some View {
        environment(\.luminaStreamingModels, models)
    }

    /// Sets the torch (flash) state.
    ///
    /// - Parameter state: The desired torch state.
    /// - Returns: A view with the torch state configured.
    func luminaTorchState(_ state: TorchState) -> some View {
        environment(\.luminaTorchState, state)
    }
}

// MARK: - Button Visibility Modifiers

public extension View {
    /// Sets the visibility of the cancel button.
    ///
    /// - Parameter visible: Whether the cancel button is visible.
    /// - Returns: A view with cancel button visibility configured.
    func luminaCancelButtonVisible(_ visible: Bool) -> some View {
        environment(\.luminaCancelButtonVisible, visible)
    }

    /// Sets the visibility of the shutter button.
    ///
    /// - Parameter visible: Whether the shutter button is visible.
    /// - Returns: A view with shutter button visibility configured.
    func luminaShutterButtonVisible(_ visible: Bool) -> some View {
        environment(\.luminaShutterButtonVisible, visible)
    }

    /// Sets the visibility of the camera switch button.
    ///
    /// - Parameter visible: Whether the camera switch button is visible.
    /// - Returns: A view with camera switch button visibility configured.
    func luminaSwitchButtonVisible(_ visible: Bool) -> some View {
        environment(\.luminaSwitchButtonVisible, visible)
    }

    /// Sets the visibility of the torch button.
    ///
    /// - Parameter visible: Whether the torch button is visible.
    /// - Returns: A view with torch button visibility configured.
    func luminaTorchButtonVisible(_ visible: Bool) -> some View {
        environment(\.luminaTorchButtonVisible, visible)
    }

    /// Hides all camera UI buttons.
    ///
    /// Use this for a completely custom camera UI where you provide your own controls.
    ///
    /// - Returns: A view with all buttons hidden.
    func luminaHideAllButtons() -> some View {
        self
            .luminaCancelButtonVisible(false)
            .luminaShutterButtonVisible(false)
            .luminaSwitchButtonVisible(false)
            .luminaTorchButtonVisible(false)
    }
}

// MARK: - Event Handler Modifiers

public extension View {
    /// Handles still image capture events.
    ///
    /// - Parameter handler: A closure called when a still image is captured.
    ///   - image: The captured `UIImage`.
    ///   - livePhotoURL: The URL of the live photo file, if live photos are enabled.
    ///   - depthData: The depth data, if depth capture is enabled. Cast to `AVDepthData`.
    /// - Returns: A view with the still image capture handler configured.
    func luminaOnStillImageCaptured(
        _ handler: @escaping @Sendable (UIImage, URL?, Any?) -> Void
    ) -> some View {
        transformEnvironment(\.luminaEventHandlers) { handlers in
            handlers.onStillImageCaptured = handler
        }
    }

    /// Handles video capture events.
    ///
    /// - Parameter handler: A closure called when video recording completes.
    ///   - url: The URL of the recorded video file.
    /// - Returns: A view with the video capture handler configured.
    func luminaOnVideoCaptured(
        _ handler: @escaping @Sendable (URL) -> Void
    ) -> some View {
        transformEnvironment(\.luminaEventHandlers) { handlers in
            handlers.onVideoCaptured = handler
        }
    }

    /// Handles video frame streaming events.
    ///
    /// - Note: Requires `luminaStreamFrames(true)` to be set.
    /// - Parameter handler: A closure called for each streamed video frame.
    ///   - frame: The video frame as a `UIImage`.
    /// - Returns: A view with the video frame streaming handler configured.
    func luminaOnVideoFrameStreamed(
        _ handler: @escaping @Sendable (UIImage) -> Void
    ) -> some View {
        transformEnvironment(\.luminaEventHandlers) { handlers in
            handlers.onVideoFrameStreamed = handler
        }
    }

    /// Handles video frame streaming with CoreML predictions.
    ///
    /// - Note: Requires `luminaStreamingModels(_:)` to be set with one or more models.
    /// - Parameter handler: A closure called for each streamed video frame with predictions.
    ///   - frame: The video frame as a `UIImage`.
    ///   - predictions: An array of `LuminaRecognitionResult` with model predictions.
    /// - Returns: A view with the prediction streaming handler configured.
    func luminaOnVideoFrameWithPredictions(
        _ handler: @escaping @Sendable (UIImage, [LuminaRecognitionResult]?) -> Void
    ) -> some View {
        transformEnvironment(\.luminaEventHandlers) { handlers in
            handlers.onVideoFrameWithPredictions = handler
        }
    }

    /// Handles depth data streaming events.
    ///
    /// - Note: Requires `luminaStreamDepthData(true)` to be set.
    /// - Parameter handler: A closure called for each streamed depth data.
    ///   - depthData: The depth data. Cast to `AVDepthData` to use.
    /// - Returns: A view with the depth data streaming handler configured.
    func luminaOnDepthDataStreamed(
        _ handler: @escaping @Sendable (Any) -> Void
    ) -> some View {
        transformEnvironment(\.luminaEventHandlers) { handlers in
            handlers.onDepthDataStreamed = handler
        }
    }

    /// Handles metadata detection events (QR codes, barcodes, faces).
    ///
    /// - Note: Requires `luminaTrackMetadata(true)` to be set.
    /// - Parameter handler: A closure called when metadata is detected.
    ///   - metadata: An array of detected metadata objects. Cast to `AVMetadataObject` or `AVMetadataFaceObject`.
    /// - Returns: A view with the metadata detection handler configured.
    func luminaOnMetadataDetected(
        _ handler: @escaping @Sendable ([Any]) -> Void
    ) -> some View {
        transformEnvironment(\.luminaEventHandlers) { handlers in
            handlers.onMetadataDetected = handler
        }
    }

    /// Handles dismiss events when the cancel button is tapped.
    ///
    /// - Parameter handler: A closure called when the camera is dismissed.
    /// - Returns: A view with the dismiss handler configured.
    func luminaOnDismissed(
        _ handler: @escaping @Sendable () -> Void
    ) -> some View {
        transformEnvironment(\.luminaEventHandlers) { handlers in
            handlers.onDismissed = handler
        }
    }

    /// Handles tap events on the camera preview.
    ///
    /// - Parameter handler: A closure called when the camera preview is tapped.
    ///   - point: The tap location in the view's coordinate space.
    /// - Returns: A view with the tap handler configured.
    func luminaOnTapped(
        _ handler: @escaping @Sendable (CGPoint) -> Void
    ) -> some View {
        transformEnvironment(\.luminaEventHandlers) { handlers in
            handlers.onTapped = handler
        }
    }
}
