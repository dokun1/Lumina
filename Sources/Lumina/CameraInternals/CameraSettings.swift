//
//  File.swift
//  
//
//  Created by David Okun on 5/25/20.
//

import Foundation
import AVFoundation

extension Lumina {
  public enum CameraPosition: String {
    case front
    case back
  }
  
  public enum Resolution: String, CaseIterable {
    case low352x288 = "Low 352x288"
    case vga640x480 = "VGA 640x480"
    case medium1280x720 = "Medium 1280x720"
    case high1920x1080 = "HD 1920x1080"
    case ultra3840x2160 = "4K 3840x2160"
    case iframe1280x720 = "iFrame 1280x720"
    case iframe960x540 = "iFrame 960x540"
    case photo = "Photo"
    case lowest = "Lowest"
    case medium = "Medium"
    case highest = "Highest"
    case inputPriority = "Input Priority"
    
    func foundationPreset() -> AVCaptureSession.Preset {
      switch self {
        case .vga640x480:
          return AVCaptureSession.Preset.vga640x480
        case .low352x288:
          return AVCaptureSession.Preset.cif352x288
        case .medium1280x720:
          return AVCaptureSession.Preset.hd1280x720
        case .high1920x1080:
          return AVCaptureSession.Preset.hd1920x1080
        case .ultra3840x2160:
          return AVCaptureSession.Preset.hd4K3840x2160
        case .iframe1280x720:
          return AVCaptureSession.Preset.iFrame1280x720
        case .iframe960x540:
          return AVCaptureSession.Preset.iFrame960x540
        case .photo:
          return AVCaptureSession.Preset.photo
        case .lowest:
          return AVCaptureSession.Preset.low
        case .medium:
          return AVCaptureSession.Preset.medium
        case .highest:
          return AVCaptureSession.Preset.high
        case .inputPriority:
          return AVCaptureSession.Preset.inputPriority
      }
    }
  }
}
