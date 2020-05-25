//
//  File.swift
//  
//
//  Created by David Okun on 5/25/20.
//

import Foundation

extension Lumina.Camera {
  internal struct Queues {
    static var videoBufferQueue = DispatchQueue(label: "com.Lumina.videoBufferQueue", attributes: .concurrent)
    static var metadataBufferQueue = DispatchQueue(label: "com.lumina.metadataBufferQueue")
    static var recognitionBufferQueue = DispatchQueue(label: "com.lumina.recognitionBufferQueue")
    static var sessionQueue = DispatchQueue(label: "com.lumina.sessionQueue")
    static var photoCollectionQueue = DispatchQueue(label: "com.lumina.photoCollectionQueue")
    static var depthDataQueue = DispatchQueue(label: "com.lumina.depthDataQueue")
  }
}
