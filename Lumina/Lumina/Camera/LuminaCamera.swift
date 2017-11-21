//
//  Camera.swift
//  CameraFramework
//
//  Created by David Okun on 8/31/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML

protocol LuminaCameraDelegate: class {
    func stillImageCaptured(camera: LuminaCamera, image: UIImage, livePhotoURL: URL?, depthData: Any?)
    func videoFrameCaptured(camera: LuminaCamera, frame: UIImage)
    func videoFrameCaptured(camera: LuminaCamera, frame: UIImage, predictedObjects: [LuminaPrediction]?)
    func depthDataCaptured(camera: LuminaCamera, depthData: Any)
    func videoRecordingCaptured(camera: LuminaCamera, videoURL: URL)
    func finishedFocus(camera: LuminaCamera)
    func detected(camera: LuminaCamera, metadata: [Any])
    func cameraSetupCompleted(camera: LuminaCamera, result: CameraSetupResult)
    func cameraBeganTakingLivePhoto(camera: LuminaCamera)
    func cameraFinishedTakingLivePhoto(camera: LuminaCamera)
}

enum CameraSetupResult: String {
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



final class LuminaCamera: NSObject {
    weak var delegate: LuminaCameraDelegate?

    var torchState = false {
        didSet {
            guard let input = self.videoInput else {
                torchState = false
                return
            }
            do {
                try input.device.lockForConfiguration()
                if torchState == false {
                    if input.device.isTorchModeSupported(.off) {
                        input.device.torchMode = .off
                        input.device.unlockForConfiguration()
                    }
                } else {
                    if input.device.isTorchModeSupported(.on) {
                        input.device.torchMode = .on
                        input.device.unlockForConfiguration()
                    }
                }
            } catch {
                torchState = false
                input.device.unlockForConfiguration()
            }
        }
    }

    var recordsVideo = false {
        didSet {
            restartVideo()
        }
    }

    var streamFrames = false {
        didSet {
            restartVideo()
        }
    }

    var trackMetadata = false {
        didSet {
            restartVideo()
        }
    }

    var captureLivePhotos = false {
        didSet {
            restartVideo()
        }
    }

    var captureDepthData = false {
        didSet {
            restartVideo()
        }
    }

    var streamDepthData = false {
        didSet {
            restartVideo()
        }
    }

    var captureHighResolutionImages = false {
        didSet {
            restartVideo()
        }
    }

    var recordingVideo: Bool = false

    var position: CameraPosition = .back {
        didSet {
            restartVideo()
        }
    }

    var resolution: CameraResolution = .highest {
        didSet {
            restartVideo()
        }
    }

    var frameRate: Int = 30 {
        didSet {
            restartVideo()
        }
    }

    var maxZoomScale: Float = MAXFLOAT

    var currentZoomScale: Float = 1.0 {
        didSet {
            updateZoom()
        }
    }

    var currentPhotoCollection: LuminaPhotoCapture?

    var recognizer: AnyObject?

    private var _streamingModel: AnyObject?
    @available(iOS 11.0, *)
    var streamingModel: MLModel? {
        get {
            return _streamingModel as? MLModel
        }
        set {
            if newValue != nil {
                _streamingModel = newValue
                recognizer = LuminaObjectRecognizer(model: newValue!)
            }
        }
    }

    var session = AVCaptureSession()
    
    fileprivate var discoverySession: AVCaptureDevice.DiscoverySession? {
        var deviceTypes = [AVCaptureDevice.DeviceType]()
        deviceTypes.append(.builtInWideAngleCamera)
        if #available(iOS 10.2, *) {
            deviceTypes.append(.builtInDualCamera)
        }
        #if swift(>=4.0.2) // Xcode 9.1 shipped with Swift 4.0.2
        if #available(iOS 11.1, *), self.captureDepthData == true {
            deviceTypes.append(.builtInTrueDepthCamera)
        }
        #endif
        return AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
    }
    
    var videoInput: AVCaptureDeviceInput?
    var audioInput: AVCaptureDeviceInput?
    var currentCaptureDevice: AVCaptureDevice?
    var videoBufferQueue = DispatchQueue(label: "com.Lumina.videoBufferQueue", attributes: .concurrent)
    var metadataBufferQueue = DispatchQueue(label: "com.lumina.metadataBufferQueue")
    var recognitionBufferQueue = DispatchQueue(label: "com.lumina.recognitionBufferQueue")
    var sessionQueue = DispatchQueue(label: "com.lumina.sessionQueue")
    var photoCollectionQueue = DispatchQueue(label: "com.lumina.photoCollectionQueue")
    var depthDataQueue = DispatchQueue(label: "com.lumina.depthDataQueue")

    var videoDataOutput: AVCaptureVideoDataOutput {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoBufferQueue)
        return output
    }
    var photoOutput = AVCapturePhotoOutput()

    private var _metadataOutput: AVCaptureMetadataOutput?
    var metadataOutput: AVCaptureMetadataOutput {
        if let existingOutput = _metadataOutput {
            return existingOutput
        }
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: metadataBufferQueue)
        _metadataOutput = output
        return output
    }

    private var _videoFileOutput: AVCaptureMovieFileOutput?
    var videoFileOutput: AVCaptureMovieFileOutput {
        if let existingOutput = _videoFileOutput {
            return existingOutput
        }
        let output = AVCaptureMovieFileOutput()
        _videoFileOutput = output
        return output
    }

    private var _depthDataOutput: AnyObject?
    @available(iOS 11.0, *)
    var depthDataOutput: AVCaptureDepthDataOutput? {
        get {
            if let existingOutput = _depthDataOutput {
                return existingOutput as? AVCaptureDepthDataOutput
            }
            let output = AVCaptureDepthDataOutput()
            output.setDelegate(self, callbackQueue: depthDataQueue)
            _depthDataOutput = output
            return output
        }
        set {
            _depthDataOutput = newValue
        }
    }

    func start() {
        self.sessionQueue.async {
            self.session.startRunning()
        }
    }

    func stop() {
        self.session.stopRunning()
    }
}
