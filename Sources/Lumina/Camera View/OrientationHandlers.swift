//
//  File.swift
//  
//
//  Created by David Okun on 5/25/20.
//

import Foundation
import AVFoundation
import UIKit.UIApplication

extension Lumina.CameraView {
  func necessaryVideoOrientation(for statusBarOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
    switch statusBarOrientation {
      case .portrait:
        return AVCaptureVideoOrientation.portrait
      case .landscapeLeft:
        return AVCaptureVideoOrientation.landscapeLeft
      case .landscapeRight:
        return AVCaptureVideoOrientation.landscapeRight
      case .portraitUpsideDown:
        return AVCaptureVideoOrientation.portraitUpsideDown
      default:
        return AVCaptureVideoOrientation.portrait
    }
  }
}
