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
    init(cameraPosition: Lumina.CameraPosition,
         customFrame: CGRect) {
      self.cameraPosition = cameraPosition
      self.customFrame = customFrame
    }
    
    private var camera = Lumina.Camera()
    
    var cameraPosition: Lumina.CameraPosition = .back
    var customFrame: CGRect = UIScreen.main.bounds
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Lumina.CameraView>) {
      self.camera.position = self.cameraPosition
      self.camera.updateVideo { result in
        if result == .videoRequiresAuthorization {
          self.camera.requestVideoPermissions()
        } else if result == .videoSuccess {
          self.camera.start()
        } else {
          print(result.rawValue)
        }
      }
    }
    
    func makeUIView(context: UIViewRepresentableContext<Lumina.CameraView>) -> UIView {
      let view = UIView()
      let previewLayer = self.camera.getPreviewLayer()
      previewLayer?.frame = customFrame
      
      let button = UIButton()
      let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .thin, scale: .medium)
      let image = UIImage(systemName: "camera.rotate", withConfiguration: config)
      // let's rig a button to see if I can get one to show up in the UI
      button.setImage(image, for: .normal)
      button.frame = CGRect(x: customFrame.maxX - 80, y: customFrame.maxY - 80, width: 60, height: 45)
      button.tintColor = .white
      button.layer.shadowOpacity = 1
      button.layer.shadowRadius = 6
      view.layer.addSublayer(previewLayer ?? CALayer())
      view.addSubview(button)
      view.bringSubviewToFront(button)
      return view
    }
  }
}

