//
//  CameraCaptureDevice.swift
//  
//
//  Created by David Okun on 5/25/20.
//

import Foundation
import AVFoundation

extension Lumina.Camera {
  func getNewVideoInputDevice() -> AVCaptureDeviceInput? {
    do {
      guard let device = getDevice(with: self.position == .front ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back) else {
        return nil
      }
      let input = try AVCaptureDeviceInput(device: device)
      return input
    } catch {
      return nil
    }
  }
  
  private func getDevice(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    #if swift(>=4.0.2)
    if #available(iOS 11.1, *), position == .front {
      if let device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
        self.currentCaptureDevice = device
        return device
      }
    }
    #endif
    if #available(iOS 10.2, *), let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position) {
      self.currentCaptureDevice = device
      return device
    } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
      self.currentCaptureDevice = device
      return device
    }
    return nil
  }
  
  func purgeVideoDevices() {
//    for oldInput in self.session.inputs where oldInput == self.videoInput {
//      self.session.removeInput(oldInput)
//    }
    for oldInput in self.session.inputs {
      self.session.removeInput(oldInput)
    }
//    for oldOutput in self.session.outputs {
//      if oldOutput == self.videoDataOutput || oldOutput == self.photoOutput || oldOutput == self.metadataOutput || oldOutput == self.videoFileOutput {
//        self.session.removeOutput(oldOutput)
//      }
//      if let dataOutput = oldOutput as? AVCaptureVideoDataOutput {
//        self.session.removeOutput(dataOutput)
//      }
//      if #available(iOS 11.0, *) {
//        if let depthOutput = oldOutput as? AVCaptureDepthDataOutput {
//          self.session.removeOutput(depthOutput)
//        }
//      }
//    }
  }
}
