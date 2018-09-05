//
//  LuminaVideoActiveFormat.swift
//  Lumina
//
//  Created by David Okun IBM on 9/4/18.
//  Copyright © 2018 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

class LuminaVideoDepthFormat: Equatable, Hashable {
    enum LuminaCameraDepthType {
        case hdis // Float16 Disparity Map
        case fdis // Float32 Disparity Map
        case hdep // Float16 Depth Map
        case fdep // Float32 Depth Map
        case unknown // catch-all
    }

    var depthType: LuminaCameraDepthType?
    private var mediaSubtypeCode: FourCharCode?
    var depthMapDimensions: CMVideoDimensions = CMVideoDimensions(width: 0, height: 0)
    var hashValue: Int

    init(description: CMFormatDescription) {
        let mediaSubtypeCode = CMFormatDescriptionGetMediaSubType(description)
        self.mediaSubtypeCode = mediaSubtypeCode
        self.depthMapDimensions = CMVideoFormatDescriptionGetDimensions(description)
        switch self.mediaSubtypeCode {
        case 1751411059:
            self.depthType = .hdis
        case 1717856627:
            self.depthType = .fdis
        case 1751410032:
            self.depthType = .hdep
        case 1717855600:
            self.depthType = .fdep
        default:
            self.depthType = .unknown
        }
        self.hashValue = Int(UInt32(self.depthMapDimensions.width) + UInt32(self.depthMapDimensions.height) + mediaSubtypeCode)
    }

    static func == (lhs: LuminaVideoDepthFormat, rhs: LuminaVideoDepthFormat) -> Bool {
        if lhs.depthMapDimensions.width != rhs.depthMapDimensions.width {
            return false
        }
        if lhs.depthMapDimensions.height != rhs.depthMapDimensions.height {
            return false
        }
        if lhs.mediaSubtypeCode != rhs.mediaSubtypeCode {
            return false
        }
        return true
    }
}

class LuminaVideoFormat: Equatable, Hashable {
    enum VideoFormatType {
        case yuv420v // 4:2:0 ratio between YUV, video range (y component) only uses 16-235 bit range
        case yuv420f // 4:2:0 ratio between YUV, full range (y component) uses 0-255 bit range
        case unknown // catch-all, make exceptions as library grows
    }

    var formatType: VideoFormatType?
    var depthFormat: LuminaVideoDepthFormat?
    var dimensions: CMVideoDimensions = CMVideoDimensions(width: 0, height: 0)
    var hashValue: Int

    init(description: CMFormatDescription, depthDescription: CMFormatDescription?) {
        self.dimensions = CMVideoFormatDescriptionGetDimensions(description)
        if let depthDescription = depthDescription {
            depthFormat = LuminaVideoDepthFormat(description: depthDescription)
        }
        let mediaSubType = CMFormatDescriptionGetMediaSubType(description)
        switch mediaSubType {
        case 875704438:
            self.formatType = .yuv420v
        case 875704422:
            self.formatType = .yuv420f
        default:
            self.formatType = .unknown
        }
        self.hashValue = Int(mediaSubType) + Int(self.dimensions.width) + Int(self.dimensions.height) + Int(depthDescription?.hashValue ?? 0)
    }

    static func == (lhs: LuminaVideoFormat, rhs: LuminaVideoFormat) -> Bool {
        if lhs.dimensions.height != rhs.dimensions.height {
            return false
        }
        if lhs.dimensions.width != rhs.dimensions.width {
            return false
        }
        if lhs.depthFormat != rhs.depthFormat {
            return false
        }
        return lhs.depthFormat == rhs.depthFormat
    }
}
