//
//  File.swift
//  
//
//  Created by David Okun on 5/25/20.
//

import Foundation
import AVFoundation

extension Lumina {
  class Camera {
    var session = AVCaptureSession()
    var currentCaptureDevice: AVCaptureDevice?
    var position: Lumina.CameraPosition = .back
    
    init() {}
    
    fileprivate var discoverySession: AVCaptureDevice.DiscoverySession? {
      var deviceTypes = [AVCaptureDevice.DeviceType]()
      deviceTypes.append(contentsOf: [.builtInDualCamera, .builtInTripleCamera, .builtInDualWideCamera, .builtInUltraWideCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera,.builtInWideAngleCamera])
      return AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
    }
    
    func start() {
      Lumina.Camera.Queues.sessionQueue.async {
        self.session.startRunning()
      }
    }
    
    func stop() {
      Lumina.Camera.Queues.sessionQueue.async {
        self.session.stopRunning()
      }
    }
  }
}
