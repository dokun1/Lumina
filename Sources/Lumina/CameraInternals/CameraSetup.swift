//
//  CameraSetup.swift
//  
//
//  Created by David Okun on 5/25/20.
//

import Foundation

extension Lumina.Camera {
  enum SetupResult: String {
    typealias RawValue = String
    case videoPermissionDenied = "Video Permissions Denied"
    case videoPermissionRestricted = "Video Permissions Restricted"
    case videoRequiresAuthorization = "Video Permissions Require Authorization"
    case audioPermissionDenied = "Audio Permissions Denied"
    case audioPermissionRestricted = "Audio Permissions Restricted"
    case audioRequiresAuthorization = "Audio Permissions Require Authorization"
    case unknownError = "Unknown Error"
    case invalidVideoDataOutput = "Invalid Video Data Output"
    case invalidVideoFileOutput = "Invalid Video File Output"
    case invalidVideoMetadataOutput = "Invalid Video Metadata Output"
    case invalidPhotoOutput = "Invalid Photo Output"
    case invalidDepthDataOutput = "Invalid Depth Data Output"
    case invalidVideoInput = "Invalid Video Input"
    case invalidAudioInput = "Invalid Audio Input"
    case requiresUpdate = "Requires AV Update"
    case videoSuccess = "Video Setup Success"
    case audioSuccess = "Audio Setup Success"
  }
}
