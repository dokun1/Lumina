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
    @available (iOS 11.0, *)
    func videoFrameCaptured(camera: LuminaCamera, frame: UIImage, predictedObjects: [LuminaRecognitionResult]?)
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

    enum TorchState {
        //swiftlint:disable identifier_name
        case on(intensity: Float)
        case off
        case auto
    }

    var torchState: TorchState = .off {
        didSet {
            guard let input = self.videoInput else {
                torchState = .off
                return
            }
            do {
                try input.device.lockForConfiguration()
                switch torchState {
                case .on(let intensity):
                    if input.device.isTorchModeSupported(.on) {
                        try input.device.setTorchModeOn(level: intensity)
                        LuminaLogger.notice(message: "torch mode set to on with intensity: \(intensity)")
                        input.device.unlockForConfiguration()
                    }
                case .off:
                    if input.device.isTorchModeSupported(.off) {
                        input.device.torchMode = .off
                        LuminaLogger.notice(message: "torch mode set to off")
                        input.device.unlockForConfiguration()
                    }
                case .auto:
                    if input.device.isTorchModeSupported(.auto) {
                        input.device.torchMode = .auto
                        LuminaLogger.notice(message: "torch mode set to auto")
                        input.device.unlockForConfiguration()
                    }
                }
            } catch {
                torchState = .off
                LuminaLogger.error(message: "cannot change torch state - defaulting to off mode")
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

    private var _streamingModels: [(AnyObject, String)]?
    @available(iOS 11.0, *)
    var streamingModels: [LuminaModel]? {
        get {
            if let existingModels = _streamingModels {
                var models = [LuminaModel]()
                for potentialModel in existingModels {
                    if let model = potentialModel.0 as? MLModel {
                        models.append(LuminaModel(model: model, type: potentialModel.1))
                    }
                }
                guard models.count > 0 else {
                    return nil
                }
                return models
            } else {
                return nil
            }
        }
        set {
            if let tuples = newValue {
                var downcastCollection = [(AnyObject, String)]()
                for tuple in tuples {
                    guard let model = tuple.model, let type = tuple.type else {
                        continue
                    }
                    downcastCollection.append((model as AnyObject, type))
                }
                _streamingModels = downcastCollection
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
        LuminaLogger.notice(message: "starting capture session")
        self.sessionQueue.async {
            self.session.startRunning()
        }
    }

    func stop() {
        LuminaLogger.notice(message: "stopping capture session")
        self.sessionQueue.async {
            self.session.stopRunning()
        }
    }
}
