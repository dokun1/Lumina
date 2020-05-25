//
//  File.swift
//  
//
//  Created by David Okun on 5/25/20.
//

import UIKit
import SwiftUI
import AVFoundation

extension Lumina {
  struct CameraView: UIViewRepresentable {
    private var camera = Lumina.Camera()
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Lumina.CameraView>) {
      self.camera.updateVideo { result in
        if result == .videoRequiresAuthorization {
          self.camera.requestVideoPermissions()
        } else if result == .videoSuccess {
          self.camera.start()
        }
      }
    }
    
    func makeUIView(context: UIViewRepresentableContext<Lumina.CameraView>) -> UIView {
      let view = UIView()
      let previewLayer = self.camera.getPreviewLayer()
      // if you are reading the next line, then yes, I know this isn't the right way to do it, but this is supposed to be an easy fix...right?
      previewLayer?.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
      view.layer.addSublayer(previewLayer ?? CALayer())
      return view
    }
  }
}

