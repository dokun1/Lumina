//
//  SessionConfiguration.swift
//  
//
//  Created by David Okun on 5/25/20.
//

import Foundation
import AVFoundation

extension Lumina.Camera {
  func requestVideoPermissions() {
    Lumina.Camera.Queues.sessionQueue.suspend()
    AVCaptureDevice.requestAccess(for: .video) { success in
      if success {
        Lumina.Camera.Queues.sessionQueue.resume()
        print("camera setup completed - requires update")
      } else {
        print("camera setup incomplete - requires permission")
      }
    }
  }
  
  func restartVideo() {
    if self.session.isRunning {
      self.stop()
      updateVideo { result in
        if result == .videoSuccess {
          self.start()
        } else {
          print("some new configuration issue is happening")
        }
      }
    }
  }
  
  private func videoSetupApproved() -> Lumina.Camera.SetupResult {
    //self.torchState = .off
    self.session.sessionPreset = .high
    guard let videoInput = self.getNewVideoInputDevice() else {
      return .invalidVideoInput
    }
    if let failureResult = checkSessionValidity(for: videoInput) {
      return failureResult
    }
    self.session.addInput(videoInput)
    self.session.commitConfiguration()
    return .videoSuccess
  }
  
  private func checkSessionValidity(for input: AVCaptureDeviceInput) -> Lumina.Camera.SetupResult? {
    guard self.session.canAddInput(input) else {
      return .invalidVideoInput
    }
    // check for other invalid types from metadata here
    
    return nil
  }
  
  func updateVideo(_ completion: @escaping (_ result: Lumina.Camera.SetupResult) -> Void) {
    Lumina.Camera.Queues.sessionQueue.async {
      self.purgeVideoDevices()
      switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
          completion(self.videoSetupApproved())
        case .denied:
          completion(.videoPermissionDenied)
        case .notDetermined:
          completion(.videoRequiresAuthorization)
        case .restricted:
          completion(.videoPermissionRestricted)
        @unknown default:
          completion(.unknownError)
      }
    }
  }
}
