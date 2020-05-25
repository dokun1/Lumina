//
//  LuminaCameraViewSettings.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

/// The position of the camera that is active on Lumina
public enum CameraPosition: String {
    /// the front facing camera of the iOS device
    case front
    /// the back (and usually main) facing camera of the iOS device
    case back
}

/// The resolution to set the camera to at any time - refer to AVCaptureSession.Preset definitions for matching, closest as of iOS 11
public enum CameraResolution: String {
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

    public static func all() -> [CameraResolution] {
        return [CameraResolution.low352x288, CameraResolution.vga640x480, CameraResolution.medium1280x720, CameraResolution.high1920x1080, CameraResolution.ultra3840x2160, CameraResolution.iframe1280x720, CameraResolution.iframe960x540, CameraResolution.photo, CameraResolution.lowest, CameraResolution.medium, CameraResolution.highest, CameraResolution.inputPriority]
    }

    // swiftlint:disable cyclomatic_complexity
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

    func getDimensions() -> CMVideoDimensions {
        switch self {
        case .vga640x480:
            return CMVideoDimensions(width: 640, height: 480)
        case .low352x288:
            return CMVideoDimensions(width: 352, height: 288)
        case .medium1280x720, .iframe1280x720, .medium:
            return CMVideoDimensions(width: 1280, height: 720)
        case .high1920x1080, .highest:
            return CMVideoDimensions(width: 1920, height: 1080)
        case .ultra3840x2160:
            return CMVideoDimensions(width: 3840, height: 2160)
        case .iframe960x540:
            return CMVideoDimensions(width: 960, height: 540)
        case .photo:
            return CMVideoDimensions(width: INT32_MAX, height: INT32_MAX)
        case .lowest:
            return CMVideoDimensions(width: 352, height: 288)
        case .inputPriority:
            return CMVideoDimensions(width: INT32_MAX, height: INT32_MAX)
        }
    }
}
