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

struct LuminaPhotoCapture {
    var camera: LuminaCamera?
    
    var stillImage: UIImage? {
        didSet {
            collectionUpdated()
        }
    }
    
    var livePhotoURL: URL? {
        didSet {
            collectionUpdated()
        }
    }
    
    private var _depthData: Any?
    @available(iOS 11.0, *)
    var depthData: AVDepthData? {
        get {
            return _depthData as? AVDepthData
        }
        set {
            if newValue != nil {
                _depthData = newValue
                collectionUpdated()
            }
        }
    }
    
    fileprivate func collectionUpdated() {
        var sendingLivePhotoURL: URL?
        var sendingDepthData: Any?
        
        guard let sendingCamera = camera, let image = stillImage else {
            return
        }
        
        if sendingCamera.captureLivePhotos == true {
            if let url = livePhotoURL {
                sendingLivePhotoURL = url
            } else {
                return
            }
        }
        
        if sendingCamera.captureDepthData == true, #available(iOS 11.0, *) {
            if let data = depthData {
                sendingDepthData = data
            } else {
                return
            }
        }
        DispatchQueue.main.async {
            sendingCamera.delegate?.stillImageCaptured(camera: sendingCamera, image: image, livePhotoURL: sendingLivePhotoURL, depthData: sendingDepthData)
        }
    }
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
    
    private(set) var recordingVideo: Bool = false
    
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
    
    private func restartVideo() {
        if self.session.isRunning {
            self.session.stopRunning()
            updateVideo({ result in
                if result == .videoSuccess {
                    self.start()
                } else {
                    self.delegate?.cameraSetupCompleted(camera: self, result: result)
                }
            })
        }
    }
    
    var maxZoomScale: Float = MAXFLOAT
    
    var currentZoomScale: Float = 1.0 {
        didSet {
            updateZoom()
        }
    }
    
    var currentPhotoCollection: LuminaPhotoCapture?
    
    fileprivate var recognizer: AnyObject?
    
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
    
    fileprivate var session = AVCaptureSession()
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
    fileprivate var videoInput: AVCaptureDeviceInput?
    fileprivate var audioInput: AVCaptureDeviceInput?
    fileprivate var currentCaptureDevice: AVCaptureDevice?
    fileprivate var videoBufferQueue = DispatchQueue(label: "com.Lumina.videoBufferQueue", attributes: .concurrent)
    fileprivate var metadataBufferQueue = DispatchQueue(label: "com.lumina.metadataBufferQueue")
    fileprivate var recognitionBufferQueue = DispatchQueue(label: "com.lumina.recognitionBufferQueue")
    fileprivate var sessionQueue = DispatchQueue(label: "com.lumina.sessionQueue")
    fileprivate var photoCollectionQueue = DispatchQueue(label: "com.lumina.photoCollectionQueue")
    fileprivate var depthDataQueue = DispatchQueue(label: "com.lumina.depthDataQueue")
    
    fileprivate var videoDataOutput: AVCaptureVideoDataOutput {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoBufferQueue)
        return output
    }
    fileprivate var photoOutput = AVCapturePhotoOutput()
    
    private var _metadataOutput: AVCaptureMetadataOutput?
    fileprivate var metadataOutput: AVCaptureMetadataOutput {
        if let existingOutput = _metadataOutput {
            return existingOutput
        }
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: metadataBufferQueue)
        _metadataOutput = output
        return output
    }
    
    private var _videoFileOutput: AVCaptureMovieFileOutput?
    fileprivate var videoFileOutput: AVCaptureMovieFileOutput {
        if let existingOutput = _videoFileOutput {
            return existingOutput
        }
        let output = AVCaptureMovieFileOutput()
        _videoFileOutput = output
        return output
    }
    
    private var _depthDataOutput: AnyObject?
    @available(iOS 11.0, *)
    fileprivate var depthDataOutput: AVCaptureDepthDataOutput? {
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
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill        
        return previewLayer
    }
    
    func captureStillImage() {
        var settings = AVCapturePhotoSettings()
        if #available(iOS 11.0, *) {
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
        }
        
        settings.isAutoStillImageStabilizationEnabled = true
        settings.flashMode = self.torchState ? .on : .off
        if self.captureLivePhotos {
            let fileName = NSTemporaryDirectory().appending("livePhoto" + Date().iso8601 + ".mov")
            settings.livePhotoMovieFileURL = URL(fileURLWithPath: fileName)
        }
        if self.captureHighResolutionImages {
            settings.isHighResolutionPhotoEnabled = true
        }
        if #available(iOS 11.0, *) {
            if self.captureDepthData && self.photoOutput.isDepthDataDeliverySupported {
                settings.isDepthDataDeliveryEnabled = true
            }
        }
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startVideoRecording() {
        recordingVideo = true
        sessionQueue.async {
            if let connection = self.videoFileOutput.connection(with: AVMediaType.video), let videoConnection = self.videoDataOutput.connection(with: AVMediaType.video) {
                connection.videoOrientation = videoConnection.videoOrientation
                connection.isVideoMirrored = self.position == .front ? true : false
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .cinematic
                }
                self.session.commitConfiguration()
            }
            let fileName = NSTemporaryDirectory().appending(Date().iso8601 + ".mov")
            self.videoFileOutput.startRecording(to: URL(fileURLWithPath: fileName), recordingDelegate: self)
        }
    }
    
    func stopVideoRecording() {
        recordingVideo = false
        sessionQueue.async {
            self.videoFileOutput.stopRecording()
        }
    }
    
    func updateOutputVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        self.videoBufferQueue.async {
            for output in self.session.outputs {
                guard let connection = output.connection(with: AVMediaType.video) else {
                    continue
                }
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = orientation
                }
            }
        }
    }
    
    func updateAudio(_ completion: @escaping (_ result: CameraSetupResult) -> Void) {
        self.sessionQueue.async {
            self.purgeAudioDevices()
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
            case .authorized:
                guard let audioInput = self.getNewAudioInputDevice() else {
                    completion(CameraSetupResult.invalidAudioInput)
                    return
                }
                guard self.session.canAddInput(audioInput) else {
                    completion(CameraSetupResult.invalidAudioInput)
                    return
                }
                self.audioInput = audioInput
                self.session.addInput(audioInput)
                completion(CameraSetupResult.audioSuccess)
                return
            case .denied:
                completion(CameraSetupResult.audioPermissionDenied)
                return
            case .notDetermined:
                completion(CameraSetupResult.audioRequiresAuthorization)
                return
            case .restricted:
                completion(CameraSetupResult.audioPermissionRestricted)
                return
            }
        }
    }
    
    func updateVideo(_ completion: @escaping (_ result: CameraSetupResult) -> Void) {
        self.sessionQueue.async {
            self.purgeVideoDevices()
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .authorized:
                self.torchState = false
                self.session.sessionPreset = .high // set to high here so that device input can be added to session. resolution can be checked for update later
                guard let videoInput = self.getNewVideoInputDevice() else {
                    completion(CameraSetupResult.invalidVideoInput)
                    return
                }
                
                guard self.session.canAddInput(videoInput) else {
                    completion(CameraSetupResult.invalidVideoInput)
                    return
                }
                
                guard self.session.canAddOutput(self.videoDataOutput) else {
                    completion(CameraSetupResult.invalidVideoDataOutput)
                    return
                }
                guard self.session.canAddOutput(self.photoOutput) else {
                    completion(CameraSetupResult.invalidPhotoOutput)
                    return
                }
                guard self.session.canAddOutput(self.metadataOutput) else {
                    completion(CameraSetupResult.invalidVideoMetadataOutput)
                    return
                }
                
                if #available(iOS 11.0, *), let depthDataOutput = self.depthDataOutput {
                    guard self.session.canAddOutput(depthDataOutput) else {
                        completion(CameraSetupResult.invalidDepthDataOutput)
                        return
                    }
                }
                
                self.videoInput = videoInput
                self.session.addInput(videoInput)
                if self.streamFrames {
                    self.session.addOutput(self.videoDataOutput)
                }
                
                self.session.addOutput(self.photoOutput)
                self.session.commitConfiguration()

                if self.recordsVideo {
                    // adding this invalidates the video data output
                    guard self.session.canAddOutput(self.videoFileOutput) else {
                        completion(CameraSetupResult.invalidVideoFileOutput)
                        return
                    }
                    self.session.addOutput(self.videoFileOutput)
                    if let connection = self.videoFileOutput.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                }
                if self.trackMetadata {
                    self.session.addOutput(self.metadataOutput)
                    self.metadataOutput.metadataObjectTypes = self.metadataOutput.availableMetadataObjectTypes
                }
                
                if self.session.canSetSessionPreset(self.resolution.foundationPreset()) {
                    self.session.sessionPreset = self.resolution.foundationPreset()
                }
 
                if self.captureHighResolutionImages && self.photoOutput.isHighResolutionCaptureEnabled {
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                } else {
                    self.captureHighResolutionImages = false
                }
                
                if self.captureLivePhotos && self.photoOutput.isLivePhotoCaptureSupported {
                    self.photoOutput.isLivePhotoCaptureEnabled = true
                } else {
                    self.captureLivePhotos = false
                }
                
                if #available(iOS 11.0, *) {
                    if self.captureDepthData && self.photoOutput.isDepthDataDeliverySupported {
                        self.photoOutput.isDepthDataDeliveryEnabled = true
                    } else {
                        self.captureDepthData = false
                    }
                } else {
                    self.captureDepthData = false
                }
                
                if #available(iOS 11.0, *) {
                    if self.streamDepthData, let depthDataOutput = self.depthDataOutput {
                        self.session.addOutput(depthDataOutput)
                    }
                }
                
                self.session.commitConfiguration()
                self.configureFrameRate()
                completion(CameraSetupResult.videoSuccess)
                break
            case .denied:
                completion(CameraSetupResult.videoPermissionDenied)
                return
            case .notDetermined:
                completion(CameraSetupResult.videoRequiresAuthorization)
                return
            case .restricted:
                completion(CameraSetupResult.videoPermissionRestricted)
                return
            }
        }
    }
    
    func start() {
        self.sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    func pause() {
        self.session.stopRunning()
    }
    
    func requestVideoPermissions() {
        self.sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { success in
            if success {
                self.sessionQueue.resume()
                self.delegate?.cameraSetupCompleted(camera: self, result: .requiresUpdate)
            } else {
                self.delegate?.cameraSetupCompleted(camera: self, result: .videoPermissionDenied)
            }
        }
    }
    
    func requestAudioPermissions() {
        self.sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.audio) { success in
            if success {
                self.sessionQueue.resume()
                self.delegate?.cameraSetupCompleted(camera: self, result: .requiresUpdate)
            } else {
                self.delegate?.cameraSetupCompleted(camera: self, result: .audioPermissionDenied)
            }
        }
    }
}

// MARK: Zoom Handling

fileprivate extension LuminaCamera {
    func updateZoom() {
        guard let input = self.videoInput else {
            return
        }
        let device = input.device
        do {
            try device.lockForConfiguration()
            let newZoomScale = min(maxZoomScale, max(Float(1.0), min(currentZoomScale, Float(device.activeFormat.videoMaxZoomFactor))))
            device.videoZoomFactor = CGFloat(newZoomScale)
            device.unlockForConfiguration()
        } catch {
            device.unlockForConfiguration()
        }
    }
}

// MARK: Focus Handling

extension LuminaCamera {
    func handleFocus(at focusPoint: CGPoint) {
        self.sessionQueue.async {
            guard let input = self.videoInput else {
                return
            }
            do {
                if input.device.isFocusModeSupported(.autoFocus) && input.device.isFocusPointOfInterestSupported {
                    try input.device.lockForConfiguration()
                    input.device.focusMode = .autoFocus
                    input.device.focusPointOfInterest = CGPoint(x: focusPoint.x, y: focusPoint.y)
                    if input.device.isExposureModeSupported(.autoExpose) && input.device.isExposurePointOfInterestSupported {
                        input.device.exposureMode = .autoExpose
                        input.device.exposurePointOfInterest = CGPoint(x: focusPoint.x, y: focusPoint.y)
                    }
                    input.device.unlockForConfiguration()
                } else {
                    self.delegate?.finishedFocus(camera: self)
                }
            } catch {
                self.delegate?.finishedFocus(camera: self)
            }
        }
    }
    
    func resetCameraToContinuousExposureAndFocus() {
        do {
            guard let input = self.videoInput else {
                print("Trying to focus, but cannot detect device input!")
                return
            }
            if input.device.isFocusModeSupported(.continuousAutoFocus) {
                try input.device.lockForConfiguration()
                input.device.focusMode = .autoFocus
                if input.device.isExposureModeSupported(.continuousAutoExposure) {
                    input.device.exposureMode = .continuousAutoExposure
                }
                input.device.unlockForConfiguration()
            }
        } catch {
            print("could not reset to continuous auto focus and exposure!!")
        }
    }
}

// MARK: CaptureDevice Handling

private extension LuminaCamera {
    func getNewVideoInputDevice() -> AVCaptureDeviceInput? {
        do {
            guard let device = getDevice(with: self.position == .front ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back) else {
                print("could not find valid AVCaptureDevice")
                return nil
            }
            let input = try AVCaptureDeviceInput(device: device)
            return input
        } catch {
            return nil
        }
    }
    
    func getNewAudioInputDevice() -> AVCaptureDeviceInput? {
        do {
            guard let device = AVCaptureDevice.default(for: AVMediaType.audio) else {
                return nil
            }
            let deviceInput = try AVCaptureDeviceInput(device: device)
            return deviceInput
        } catch {
            return nil
        }
    }
    
    func purgeAudioDevices() {
        for oldInput in self.session.inputs {
            if oldInput == self.audioInput {
                self.session.removeInput(oldInput)
            }
        }
    }
    
    func purgeVideoDevices() {
        for oldInput in self.session.inputs {
            if oldInput == self.videoInput {
                self.session.removeInput(oldInput)
            }
        }
        for oldOutput in self.session.outputs {
            if oldOutput == self.videoDataOutput || oldOutput == self.photoOutput || oldOutput == self.metadataOutput || oldOutput == self.videoFileOutput  {
                self.session.removeOutput(oldOutput)
            }
            if let dataOutput = oldOutput as? AVCaptureVideoDataOutput {
                self.session.removeOutput(dataOutput)
            }
            if #available(iOS 11.0, *) {
                if let depthOutput = oldOutput as? AVCaptureDepthDataOutput {
                    self.session.removeOutput(depthOutput)
                }
            }
        }
    }
    
    func getDevice(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        #if swift(>=4.0.2)
        if #available(iOS 11.1, *), position == .front {
            if let device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
                return device
            }
        }
        #endif
        if #available(iOS 10.2, *), let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position) {
            return device
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return device
        }
        return nil
    }
    
    func configureFrameRate() {
        guard let device = self.currentCaptureDevice else {
            return
        }
        for vFormat in device.formats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(vFormat.formatDescription)
            let ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
            guard let frameRate = ranges.first else {
                continue
            }
            if frameRate.maxFrameRate >= Float64(self.frameRate) &&
                frameRate.minFrameRate <= Float64(self.frameRate) &&
                self.resolution.getDimensions().width == dimensions.width &&
                self.resolution.getDimensions().height == dimensions.height &&
                CMFormatDescriptionGetMediaSubType(vFormat.formatDescription) == 875704422  { // meant for full range 420f
                try! device.lockForConfiguration()
                device.activeFormat = vFormat as AVCaptureDevice.Format
                device.activeVideoMinFrameDuration = CMTimeMake(1, Int32(self.frameRate))
                device.activeVideoMaxFrameDuration = CMTimeMake(1, Int32(self.frameRate))
                device.unlockForConfiguration()
                break
            }
        }
    }
}

// MARK: Still Photo Capture

extension LuminaCamera: AVCapturePhotoCaptureDelegate {
    @available (iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let image = photo.normalizedImage(forCameraPosition: self.position) else {
            return
        }
        photoCollectionQueue.sync {
            if self.currentPhotoCollection == nil {
                var collection = LuminaPhotoCapture()
                collection.camera = self
                collection.depthData = photo.depthData
                collection.stillImage = image
                self.currentPhotoCollection = collection
            } else {
                guard var collection = self.currentPhotoCollection else {
                    return
                }
                collection.camera = self
                collection.depthData = photo.depthData
                collection.stillImage = image
                self.currentPhotoCollection = collection
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if #available(iOS 11.0, *) { // make use of AVCapturePhotoOutput
            return
        } else {
            guard let buffer = photoSampleBuffer else {
                return
            }
            guard let image = buffer.normalizedStillImage(forCameraPosition: self.position) else {
                return
            }
            delegate?.stillImageCaptured(camera: self, image: image, livePhotoURL: nil, depthData: nil)
        }
    }
}

// MARK: AVCapturePhoto Methods
@available (iOS 11.0, *)
extension AVCapturePhoto {
    func normalizedImage(forCameraPosition position: CameraPosition) -> UIImage? {
        guard let cgImage = self.cgImageRepresentation() else {
            return nil
        }
        return UIImage(cgImage: cgImage.takeUnretainedValue() , scale: 1.0, orientation: getImageOrientation(forCamera: position))
    }
    
    private func getImageOrientation(forCamera: CameraPosition) -> UIImageOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            return forCamera == .back ? .down : .upMirrored
        case .landscapeRight:
            return forCamera == .back ? .up : .downMirrored
        case .portraitUpsideDown:
            return forCamera == .back ? .left : .rightMirrored
        case .portrait:
            return forCamera == .back ? .right : .leftMirrored
        case .unknown:
            return forCamera == .back ? .right : .leftMirrored
        }
    }
}

// MARK: Video Frame Streaming

extension LuminaCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = sampleBuffer.normalizedVideoFrame() else {
            return
        }
        if #available(iOS 11.0, *) {
            guard let recognizer = self.recognizer as? LuminaObjectRecognizer else {
                DispatchQueue.main.async {
                    self.delegate?.videoFrameCaptured(camera: self, frame: image)
                }
                return
            }
            recognizer.recognize(from: image, completion: { predictions in
                DispatchQueue.main.async {
                    self.delegate?.videoFrameCaptured(camera: self, frame: image, predictedObjects: predictions)
                }
            })
        } else {
            DispatchQueue.main.async {
                self.delegate?.videoFrameCaptured(camera: self, frame: image)
            }
        }
    }
}

// MARK: Image Normalization Methods

extension CMSampleBuffer {
    func normalizedStillImage(forCameraPosition position: CameraPosition) -> UIImage? {
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: self, previewPhotoSampleBuffer: nil) else {
            return nil
        }
        guard let dataProvider = CGDataProvider(data: imageData as CFData) else {
            return nil
        }
        guard let cgImageRef = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent) else {
            return nil
        }
        return UIImage(cgImage: cgImageRef, scale: 1.0, orientation: getImageOrientation(forCamera: position))
    }
    
    func normalizedVideoFrame() -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
            return nil
        }
        let coreImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let context: CIContext = CIContext()
        guard let sample: CGImage = context.createCGImage(coreImage, from: coreImage.extent) else {
            return nil
        }
        return UIImage(cgImage: sample)
    }
    
    private func getImageOrientation(forCamera: CameraPosition) -> UIImageOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            return forCamera == .back ? .down : .upMirrored
        case .landscapeRight:
            return forCamera == .back ? .up : .downMirrored
        case .portraitUpsideDown:
            return forCamera == .back ? .left : .rightMirrored
        case .portrait:
            return forCamera == .back ? .right : .leftMirrored
        case .unknown:
            return forCamera == .back ? .right : .leftMirrored
        }
    }
}

// MARK: MetadataOutput Delegate Methods

extension LuminaCamera: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard case self.trackMetadata = true else {
            return
        }
        DispatchQueue.main.async {
            self.delegate?.detected(camera: self, metadata: metadataObjects)
        }
    }
}

// MARK: DepthDataOutput Delegate Methods

@available(iOS 11.0, *)
extension LuminaCamera: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            self.delegate?.depthDataCaptured(camera: self, depthData: depthData)
        }
    }
    
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didDrop depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection, reason: AVCaptureOutput.DataDroppedReason) {
        // place to handle dropped AVDepthData if we need it
    }
}

// MARK: RecordingOutput Delegate Methods

extension LuminaCamera: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            if error == nil, let delegate = self.delegate {
                delegate.videoRecordingCaptured(camera: self, videoURL: outputFileURL)
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if self.captureLivePhotos {
            self.delegate?.cameraBeganTakingLivePhoto(camera: self)
        }
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if self.captureLivePhotos {
            self.delegate?.cameraFinishedTakingLivePhoto(camera: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        photoCollectionQueue.sync {
            if self.currentPhotoCollection == nil {
                var collection = LuminaPhotoCapture()
                collection.camera = self
                collection.livePhotoURL = outputFileURL
                self.currentPhotoCollection = collection
            } else {
                guard var collection = self.currentPhotoCollection else {
                    return
                }
                collection.camera = self
                collection.livePhotoURL = outputFileURL
                self.currentPhotoCollection = collection
            }
        }
    }
}

extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}
