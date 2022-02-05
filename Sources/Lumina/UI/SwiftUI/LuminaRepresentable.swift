//
//  LuminaRepresentable.swift
//  
//
//  Created by David Okun on 2/5/22.
//

import SwiftUI
import Foundation

public struct LuminaView: UIViewControllerRepresentable {
  private var controllerReference: LuminaViewController?
  
  // - MARK: Settings
  
  /// Use this to determine whether the camera should start on the front facing camera or not.
  public var cameraPosition: CameraPosition = .back
  public var cameraResolution: CameraResolution = .highest
  public var frameRate: Int = 30
  public var captureLivePhotos: Bool = false
  public var shouldStreamFrames: Bool = false
  public var canRecordVideo: Bool = false
  public var streamingModels: [LuminaModel]? = nil
  public var textPrompt: String = ""
  
  // - MARK: Actions
  /// This closure will fire whenever you capture a still image
  public var photoCaptured: ((UIImage, URL?, Any?) -> ())? = nil
  public var videoCaptured: ((URL) -> ())? = nil
  public var depthDataStreamed: ((Any) -> ())? = nil
  public var videoFrameStreamed: ((UIImage) -> ())? = nil
  public var predictionsStreamed: ((UIImage, [LuminaRecognitionResult]?) -> ())? = nil
  public var viewDismissed: (() -> ())? = nil
  
  public func updateUIViewController(_ luminaController: LuminaViewController, context: Context) {
    updateSettings(for: luminaController)
  }
  
  public func makeUIViewController(context: Context) -> LuminaViewController {
    let controller = LuminaViewController()
    controller.delegate = context.coordinator
    controller.startCamera()
    return controller
  }
  
  public func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  private mutating func updateSettings(for controller: LuminaViewController) {
    controller.resolution = .highest
    controller.streamFrames = self.shouldStreamFrames
    controller.captureLivePhotos = self.captureLivePhotos
    controller.position = self.cameraPosition
    controller.resolution = self.cameraResolution
    controller.recordsVideo = self.canRecordVideo
    controller.streamingModels = self.streamingModels
    controller.frameRate = self.frameRate
    controller.textPrompt = self.textPrompt
    self.controllerReference = controller
  }
  
  public class Coordinator: NSObject, LuminaDelegate {
    var parent: LuminaView
    
    init(_ parent: LuminaView) {
      self.parent = parent
    }
    
    public var torchState: TorchState {
      get {
        return self.parent.controllerReference?.torchState ?? .off
      }
      set(newValue) {
        self.parent.controllerReference?.camera?.torchState = newValue
      }
    }
    
    public func dismissed(controller: LuminaViewController) {
      if let viewDismissed = self.parent.viewDismissed {
        viewDismissed()
      }
    }
    
    public func captured(videoAt: URL, from controller: LuminaViewController) {
      if let videoCaptured = self.parent.videoCaptured {
        videoCaptured(videoAt)
      }
    }
    
    public func streamed(videoFrame: UIImage, with predictions: [LuminaRecognitionResult]?, from controller: LuminaViewController) {
      if let predictionsStreamed = self.parent.predictionsStreamed {
        predictionsStreamed(videoFrame, predictions)
      }
    }
    
    public func streamed(videoFrame: UIImage, from controller: LuminaViewController) {
      if let videoFrameStreamed = self.parent.videoFrameStreamed {
        videoFrameStreamed(videoFrame)
      }
    }
    
    public func streamed(depthData: Any, from controller: LuminaViewController) {
      if let depthDataStreamed = self.parent.depthDataStreamed {
        depthDataStreamed(depthData)
      }
    }
    
    public func captured(stillImage: UIImage, livePhotoAt: URL?, depthData: Any?, from controller: LuminaViewController) {
      if let photoCaptured = self.parent.photoCaptured {
        photoCaptured(stillImage, livePhotoAt, depthData)
      }
    }
  }
}
