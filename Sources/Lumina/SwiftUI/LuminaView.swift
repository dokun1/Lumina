//
//  LuminaView.swift
//  Lumina
//
//  Created by Claude on 2026-01-25.
//  Copyright © 2026 David Okun. All rights reserved.
//

import SwiftUI
import AVFoundation
import CoreML

/// A SwiftUI view that wraps the LuminaViewController camera interface.
///
/// Use `LuminaView` to add camera functionality to your SwiftUI app. Configure the camera
/// using the builder-pattern view modifiers provided by the framework.
///
/// # Example Usage
///
/// ```swift
/// struct CameraScreen: View {
///     var body: some View {
///         LuminaView()
///             .luminaCameraPosition(.back)
///             .luminaResolution(.high1920x1080)
///             .luminaTextPrompt("Point camera at QR code")
///             .luminaTrackMetadata(true)
///             .luminaOnMetadataDetected { metadata in
///                 print("Detected: \(metadata)")
///             }
///             .luminaOnStillImageCaptured { image, livePhotoURL, depthData in
///                 print("Captured image: \(image)")
///             }
///     }
/// }
/// ```
public struct LuminaView: UIViewControllerRepresentable {
    public typealias UIViewControllerType = LuminaViewController

    @Environment(\.luminaCameraPosition) private var cameraPosition
    @Environment(\.luminaRecordsVideo) private var recordsVideo
    @Environment(\.luminaStreamFrames) private var streamFrames
    @Environment(\.luminaTrackMetadata) private var trackMetadata
    @Environment(\.luminaTextPrompt) private var textPrompt
    @Environment(\.luminaResolution) private var resolution
    @Environment(\.luminaFrameRate) private var frameRate
    @Environment(\.luminaCaptureLivePhotos) private var captureLivePhotos
    @Environment(\.luminaCaptureDepthData) private var captureDepthData
    @Environment(\.luminaStreamDepthData) private var streamDepthData
    @Environment(\.luminaMaxZoomScale) private var maxZoomScale
    @Environment(\.luminaCurrentZoomScale) private var currentZoomScale
    @Environment(\.luminaStreamingModels) private var streamingModels
    @Environment(\.luminaTorchState) private var torchState
    @Environment(\.luminaCancelButtonVisible) private var cancelButtonVisible
    @Environment(\.luminaShutterButtonVisible) private var shutterButtonVisible
    @Environment(\.luminaSwitchButtonVisible) private var switchButtonVisible
    @Environment(\.luminaTorchButtonVisible) private var torchButtonVisible
    @Environment(\.luminaEventHandlers) private var eventHandlers

    /// Creates a new LuminaView with default configuration.
    ///
    /// Configure the view using the builder-pattern view modifiers.
    public init() {}

    public func makeUIViewController(context: Context) -> LuminaViewController {
        let controller = LuminaViewController()
        controller.delegate = context.coordinator
        configureController(controller)
        return controller
    }

    public func updateUIViewController(_ controller: LuminaViewController, context: Context) {
        configureController(controller)
        context.coordinator.eventHandlers = eventHandlers
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(eventHandlers: eventHandlers)
    }

    private func configureController(_ controller: LuminaViewController) {
        controller.position = cameraPosition
        controller.recordsVideo = recordsVideo
        controller.streamFrames = streamFrames
        controller.trackMetadata = trackMetadata
        controller.textPrompt = textPrompt
        controller.resolution = resolution
        controller.frameRate = frameRate
        controller.captureLivePhotos = captureLivePhotos
        controller.captureDepthData = captureDepthData
        controller.streamDepthData = streamDepthData
        controller.maxZoomScale = maxZoomScale
        controller.currentZoomScale = currentZoomScale
        controller.streamingModels = streamingModels
        controller.torchState = torchState

        controller.setCancelButton(visible: cancelButtonVisible)
        controller.setShutterButton(visible: shutterButtonVisible)
        controller.setSwitchButton(visible: switchButtonVisible)
        controller.setTorchButton(visible: torchButtonVisible)
    }

    /// Coordinator that acts as the LuminaDelegate and forwards events to SwiftUI handlers.
    public class Coordinator: NSObject, LuminaDelegate {
        var eventHandlers: LuminaEventHandlers

        init(eventHandlers: LuminaEventHandlers) {
            self.eventHandlers = eventHandlers
        }

        public func captured(stillImage: UIImage, livePhotoAt: URL?, depthData: Any?, from controller: LuminaViewController) {
            eventHandlers.onStillImageCaptured?(stillImage, livePhotoAt, depthData)
        }

        public func captured(videoAt: URL, from controller: LuminaViewController) {
            eventHandlers.onVideoCaptured?(videoAt)
        }

        public func streamed(videoFrame: UIImage, from controller: LuminaViewController) {
            eventHandlers.onVideoFrameStreamed?(videoFrame)
        }

        public func streamed(videoFrame: UIImage, with predictions: [LuminaRecognitionResult]?, from controller: LuminaViewController) {
            eventHandlers.onVideoFrameWithPredictions?(videoFrame, predictions)
        }

        public func streamed(depthData: Any, from controller: LuminaViewController) {
            eventHandlers.onDepthDataStreamed?(depthData)
        }

        public func detected(metadata: [Any], from controller: LuminaViewController) {
            eventHandlers.onMetadataDetected?(metadata)
        }

        public func dismissed(controller: LuminaViewController) {
            eventHandlers.onDismissed?()
        }

        public func tapped(at point: CGPoint, from controller: LuminaViewController) {
            eventHandlers.onTapped?(point)
        }
    }
}

// MARK: - Preview Provider

@available(iOS 17.0, *)
#Preview {
    LuminaView()
        .luminaCameraPosition(.back)
        .luminaResolution(.highest)
}
