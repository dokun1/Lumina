//
//  CameraViewController.swift
//  CameraFramework
//
//  Created by David Okun on 8/29/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML

/// Delegate for returning information to the application utilizing Lumina
public protocol LuminaDelegate: class {
    
    /// Triggered whenever a still image is captured by the user of Lumina
    ///
    /// - Parameters:
    ///   - stillImage: the image captured by Lumina
    ///   - controller: the instance of Lumina that captured the still image
    func captured(stillImage: UIImage, from controller: LuminaViewController)
    
    /// Triggered whenever a video is captured by the user of Lumina
    ///
    /// - Parameters:
    ///   - videoAtURL: the URL where the video file can be located and used
    ///   - controller: the instance of Lumina that captured the still image
    func captured(videoAtURL: URL, from controller: LuminaViewController)
    
    /// Triggered whenever streamFrames is set to true on Lumina, and streams video frames as UIImage instances
    ///
    /// - Note: Will not be triggered unless streamFrames is true. False is default value
    /// - Parameters:
    ///   - videoFrame: the frame captured by Lumina
    ///   - controller: the instance of Lumina that is streaming the frames
    func streamed(videoFrame: UIImage, from controller: LuminaViewController)
    
    /// Triggered whenever a CoreML model is given to Lumina, and Lumina streams a video frame alongside a prediction
    ///
    /// - Note: Will not be triggered unless streamingModel resolves to not nil. Leaving the streamingModel parameter unset will not trigger this method
    /// - Warning: The other method for passing video frames back via a delegate will not be triggered in the presence of a CoreML model
    /// - Parameters:
    ///   - videoFrame: the frame captured by Lumina
    ///   - predictions: the predictions made by the model used with Lumina
    ///   - controller: the instance of Lumina that is streaming the frames
    func streamed(videoFrame: UIImage, with predictions: [LuminaPrediction]?, from controller: LuminaViewController)
    
    /// Triggered whenever trackMetadata is set to true on Lumina, and streams metadata detected in the form of QR codes, bar codes, or faces
    ///
    /// - Note: For list of all machine readable object types, aside from QR codes or faces, click [here](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject/machine_readable_object_types).
    ///
    /// - Warning: Objects returned in array must be casted to AVMetadataObject or AVMetadataFaceObject individually.
    ///
    /// - Parameters:
    ///   - metadata: the array of metadata that is captured.
    ///   - controller: the instance of Lumina that is streaming the metadata
    func detected(metadata: [Any], from controller: LuminaViewController)
    
    /// Triggered whenever the cancel button is tapped on Lumina, with the intent of dismissing the UIViewController
    ///
    /// - Note: This is most usually used whenever
    ///
    /// - Parameter controller: the instance of Lumina that cancel was tapped on
    func dismissed(controller: LuminaViewController)
}

// MARK: Extension to make delegate functions optional

public extension LuminaDelegate {
    func captured(stillImage: UIImage, from controller: LuminaViewController) {}
    func captured(videoAtURL: URL, from controller: LuminaViewController) {}
    func streamed(videoFrame: UIImage, from controller: LuminaViewController) {}
    func streamed(videoFrame: UIImage, with predictions: [LuminaPrediction]?, from controller: LuminaViewController) {}
    func detected(metadata: [Any], from controller: LuminaViewController) {}
    func dismissed(controller: LuminaViewController) {}
}

/// The position of the camera that is active on Lumina
public enum CameraPosition {
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
        case .medium1280x720:
            return CMVideoDimensions(width: 1280, height: 720)
        case .high1920x1080:
            return CMVideoDimensions(width: 1920, height: 1080)
        case .ultra3840x2160:
            return CMVideoDimensions(width: 3840, height: 2160)
        case .iframe1280x720:
            return CMVideoDimensions(width: 1280, height: 720)
        case .iframe960x540:
            return CMVideoDimensions(width: 960, height: 540)
        case .photo:
            return CMVideoDimensions(width: INT32_MAX, height: INT32_MAX)
        case .lowest:
            return CMVideoDimensions(width: 352, height: 288)
        case .medium:
            return CMVideoDimensions(width: 1280, height: 720)
        case .highest:
            return CMVideoDimensions(width: 1920, height: 1080)
        case .inputPriority:
            return CMVideoDimensions(width: INT32_MAX, height: INT32_MAX)
        }
    }
}

/// The main class that developers should interact with and instantiate when using Lumina
public final class LuminaViewController: UIViewController {
    var camera: LuminaCamera?
    
    private var _previewLayer: AVCaptureVideoPreviewLayer?
    var previewLayer: AVCaptureVideoPreviewLayer {
        if let currentLayer = _previewLayer {
            return currentLayer
        }
        guard let camera = self.camera, let layer = camera.getPreviewLayer() else {
            return AVCaptureVideoPreviewLayer()
        }
        layer.frame = self.view.bounds
        _previewLayer = layer
        return layer
    }
    
    private var _zoomRecognizer: UIPinchGestureRecognizer?
    var zoomRecognizer: UIPinchGestureRecognizer {
        if let currentRecognizer = _zoomRecognizer {
            return currentRecognizer
        }
        let recognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGestureRecognizer(recognizer:)))
        recognizer.delegate = self
        _zoomRecognizer = recognizer
        return recognizer
    }
    
    private var _focusRecognizer: UITapGestureRecognizer?
    var focusRecognizer: UITapGestureRecognizer {
        if let currentRecognizer = _focusRecognizer {
            return currentRecognizer
        }
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(recognizer:)))
        recognizer.delegate = self
        _focusRecognizer = recognizer
        return recognizer
    }
    
    private var _feedbackGenerator: LuminaHapticFeedbackGenerator?
    var feedbackGenerator: LuminaHapticFeedbackGenerator {
        if let currentGenerator = _feedbackGenerator {
            return currentGenerator
        }
        let generator = LuminaHapticFeedbackGenerator()
        _feedbackGenerator = generator
        return generator
    }
    
    private var _cancelButton: LuminaButton?
    var cancelButton: LuminaButton {
        if let currentButton = _cancelButton {
            return currentButton
        }
        let button = LuminaButton(with: SystemButtonType.cancel)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        _cancelButton = button
        return button
    }
    
    private var _shutterButton: LuminaButton?
    var shutterButton: LuminaButton {
        if let currentButton = _shutterButton {
            return currentButton
        }
        let button = LuminaButton(with: SystemButtonType.shutter)
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(shutterButtonTapped)))
        button.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(shutterButtonLongPressed)))
        _shutterButton = button
        return button
    }
    
    private var _switchButton: LuminaButton?
    var switchButton: LuminaButton {
        if let currentButton = _switchButton {
            return currentButton
        }
        let button = LuminaButton(with: SystemButtonType.cameraSwitch)
        button.addTarget(self, action: #selector(switchButtonTapped), for: .touchUpInside)
        _switchButton = button
        return button
    }
    
    private var _torchButton: LuminaButton?
    var torchButton: LuminaButton {
        if let currentButton = _torchButton {
            return currentButton
        }
        let button = LuminaButton(with: SystemButtonType.torch)
        button.addTarget(self, action: #selector(torchButtonTapped), for: .touchUpInside)
        _torchButton = button
        return button
    }
    
    private var _textPromptView: LuminaTextPromptView?
    var textPromptView: LuminaTextPromptView {
        if let existingView = _textPromptView {
            return existingView
        }
        let promptView = LuminaTextPromptView()
        _textPromptView = promptView
        return promptView
    }
    
    fileprivate var isUpdating = false
    
    /// The delegate for streaming output from Lumina
    weak open var delegate: LuminaDelegate?
    
    /// The position of the camera
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    open var position: CameraPosition = .back {
        didSet {
            guard let camera = self.camera else {
                return
            }
            camera.position = position
        }
    }
    
    /// Set this to choose whether or not Lumina will be able to record video by holding down the capture button
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    ///
    /// - Warning: This setting takes precedence over video data streaming - if this is turned on, frames cannot be streamed, nor can CoreML be used via Lumina's recognizer mechanism. 
    open var recordsVideo = false {
        didSet {
            if let camera = self.camera {
                camera.recordsVideo = recordsVideo
            }
        }
    }
    
    /// Set this to choose whether or not Lumina will stream video frames through the delegate
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    ///
    /// - Warning: Will not do anything if delegate is not implemented
    open var streamFrames = false {
        didSet {
            if let camera = self.camera {
                camera.streamFrames = streamFrames
            }
        }
    }
    
    /// Set this to choose whether or not Lumina will stream machine readable metadata through the delegate
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    ///
    /// - Warning: Will not do anything if delegate is not implemented
    open var trackMetadata = false {
        didSet {
            if let camera = self.camera {
                camera.trackMetadata = trackMetadata
            }
        }
    }
    
    /// Lumina comes ready with a view for a text prompt to give instructions to the user, and this is where you can set the text of that prompt
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    ///
    /// - Warning: If left empty, or unset, no view will be present, but view will be created if changed
    open var textPrompt = "" {
        didSet {
            self.textPromptView.updateText(to: textPrompt)
        }
    }
    
    /// Set this to choose a resolution for the camera at any time - defaults to highest resolution possible for camera
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    open var resolution: CameraResolution = .highest {
        didSet {
            if let camera = self.camera {
                camera.resolution = resolution
            }
        }
    }
    
    /// Set this to choose a frame rate for the camera at any time - defaults to 30 if query is not available
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    open var frameRate: Int = 30 {
        didSet {
            if let camera = self.camera {
                camera.frameRate = frameRate
            }
        }
    }
    
    private var _streamingModel: AnyObject?
    
    /// A model that will be used when streaming images for object recognition
    ///
    /// - Note: Only works on iOS 11 and up
    ///
    /// - Warning: If this is set, streamFrames is over-ridden to true
    @available(iOS 11.0, *)
    open var streamingModel: MLModel? {
        get {
            return _streamingModel as? MLModel
        }
        set {
            if newValue != nil {
                _streamingModel = newValue
                self.streamFrames = true
                if let camera = self.camera {
                    camera.streamingModel = newValue
                }
            }
        }
    }
    
    /// The maximum amout of zoom that Lumina can use
    ///
    /// - Note: Default value will rely on whatever the active device can handle, if this is not explicitly set
    open var maxZoomScale: Float = MAXFLOAT {
        didSet {
            if let camera = camera {
                camera.maxZoomScale = maxZoomScale
            }
        }
    }
    
    fileprivate var currentZoomScale: Float = 1.0 {
        didSet {
            if let camera = self.camera {
                camera.currentZoomScale = currentZoomScale
            }
        }
    }
    
    fileprivate var beginZoomScale: Float = 1.0
    
    /// run this in order to create Lumina
    public init() {
        super.init(nibName: nil, bundle: nil)
        let camera = LuminaCamera()
        camera.delegate = self
        self.camera = camera
    }
    
    /// run this in order to create Lumina with a storyboard
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let camera = LuminaCamera()
        camera.delegate = self
        self.camera = camera
    }
    
    /// override with caution
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Camera framework is overloading on memory")
    }
    
    /// override with caution
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        createUI()
        if let camera = self.camera {
            camera.updateVideo({ result in
                self.handleCameraSetupResult(result)
            })
            camera.updateAudio({ result in
                self.handleCameraSetupResult(result)
            })
        }
    }
    
    public override var shouldAutorotate: Bool {
        guard let camera = self.camera else {
            return true
        }
        return !camera.recordingVideo
    }
    
    /// override with caution
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        if let camera = self.camera {
            camera.pause()
        }
    }
    
    /// override with caution
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if self.camera?.recordingVideo == true {
            return
        }
        updateUI(orientation: UIApplication.shared.statusBarOrientation)
        updateButtonFrames()
    }
    
    /// override with caution
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    /// returns a string of the version of Lumina currently in use, follows semantic versioning.
    open class func getVersion() -> String? {
        let bundle = Bundle(for: LuminaViewController.self)
        guard let infoDictionary = bundle.infoDictionary else {
            return nil
        }
        guard let versionString = infoDictionary["CFBundleShortVersionString"] as? String else {
            return nil
        }
        return versionString
    }
}

// MARK: User Interface Creation

fileprivate extension LuminaViewController {
    @objc func handlePinchGestureRecognizer(recognizer: UIPinchGestureRecognizer) {
        guard self.position == .back else {
            return
        }
        currentZoomScale = min(maxZoomScale, max(1.0, beginZoomScale * Float(recognizer.scale)))
    }
    
    @objc func handleTapGestureRecognizer(recognizer: UITapGestureRecognizer) {
        if self.position == .back {
            focusCamera(at: recognizer.location(in: self.view))
        }
    }
    
    func createUI() {
        self.view.layer.addSublayer(self.previewLayer)
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.shutterButton)
        self.view.addSubview(self.switchButton)
        self.view.addSubview(self.torchButton)
        self.view.addSubview(self.textPromptView)
        self.view.addGestureRecognizer(self.zoomRecognizer)
        self.view.addGestureRecognizer(self.focusRecognizer)
        enableUI(valid: false)
    }
    
    func enableUI(valid: Bool) {
        DispatchQueue.main.async {
            self.shutterButton.isEnabled = valid
            self.switchButton.isEnabled = valid
            self.torchButton.isEnabled = valid
        }
    }
    
    func updateUI(orientation: UIInterfaceOrientation) {
        guard let connection = self.previewLayer.connection, connection.isVideoOrientationSupported else {
            return
        }
        self.previewLayer.frame = self.view.bounds
        connection.videoOrientation = necessaryVideoOrientation(for: orientation)
        if let camera = self.camera {
            camera.updateOutputVideoOrientation(connection.videoOrientation)
        }
    }
    
    func updateButtonFrames() {
        self.cancelButton.center = CGPoint(x: self.view.frame.minX + 55, y: self.view.frame.maxY - 45)
        if self.view.frame.width > self.view.frame.height {
            self.shutterButton.center = CGPoint(x: self.view.frame.maxX - 45, y: self.view.frame.midY)
        } else {
            self.shutterButton.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.maxY - 45)
        }
        self.switchButton.center = CGPoint(x: self.view.frame.maxX - 25, y: self.view.frame.minY + 25)
        self.torchButton.center = CGPoint(x: self.view.frame.minX + 25, y: self.view.frame.minY + 25)
        self.textPromptView.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + 45)
        self.textPromptView.layoutSubviews()
    }
    
    private func handleCameraSetupResult(_ result: CameraSetupResult) {
        DispatchQueue.main.async {
            switch result {
            case .videoSuccess:
                guard let camera = self.camera else {
                    return
                }
                self.enableUI(valid: true)
                camera.start()
                break
            case .audioSuccess:
                break
            case .requiresUpdate:
                guard let camera = self.camera else {
                    return
                }
                camera.updateVideo({ result in
                    self.handleCameraSetupResult(result)
                })
                break
            case .videoPermissionDenied:
                self.textPrompt = "Camera permissions for Lumina have been previously denied - please access your privacy settings to change this."
                break
            case .videoPermissionRestricted:
                self.textPrompt = "Camera permissions for Lumina have been restricted - please access your privacy settings to change this."
                break
            case .videoRequiresAuthorization:
                guard let camera = self.camera else {
                    break
                }
                camera.requestVideoPermissions()
                break
            case .audioPermissionRestricted:
                self.textPrompt = "Audio permissions for Lumina have been restricted - please access your privacy settings to change this."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.textPrompt = ""
                }
                break
            case .audioRequiresAuthorization:
                guard let camera = self.camera else {
                    break
                }
                camera.requestAudioPermissions()
                break
            case .audioPermissionDenied:
                self.textPrompt = "Audio permissions for Lumina have been previously denied - please access your privacy settings to change this."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.textPrompt = ""
                }
                break
            case .invalidVideoDataOutput, .invalidVideoInput, .invalidPhotoOutput, .invalidVideoMetadataOutput, .invalidVideoFileOutput, .invalidAudioInput:
                self.textPrompt = "\(result.rawValue) - please try again"
                break
            case .unknownError:
                self.textPrompt = "Unknown error occurred while loading Lumina - please try again"
                break
            }
        }
    }
    
    private func necessaryVideoOrientation(for statusBarOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch statusBarOrientation {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
}

// MARK: CameraDelegate Functions

extension LuminaViewController: LuminaCameraDelegate {
    func videoRecordingCaptured(camera: LuminaCamera, videoURL: URL) {
        delegate?.captured(videoAtURL: videoURL, from: self)
    }
    
    func videoFrameCaptured(camera: LuminaCamera, frame: UIImage, predictedObjects: [LuminaPrediction]?) {
        delegate?.streamed(videoFrame: frame, with: predictedObjects, from: self)
    }
    
    func finishedFocus(camera: LuminaCamera) {
        DispatchQueue.main.async {
            self.isUpdating = false
        }
    }
    
    func stillImageCaptured(camera: LuminaCamera, image: UIImage) {
        delegate?.captured(stillImage: image, from: self)
    }
    
    func videoFrameCaptured(camera: LuminaCamera, frame: UIImage) {
        delegate?.streamed(videoFrame: frame, from: self)
    }
    
    func detected(camera: LuminaCamera, metadata: [Any]) {
        delegate?.detected(metadata: metadata, from: self)
    }
    
    func cameraSetupCompleted(camera: LuminaCamera, result: CameraSetupResult) {
        handleCameraSetupResult(result)
    }
}

// MARK: UIButton Functions

fileprivate extension LuminaViewController {
    @objc func cancelButtonTapped() {
        delegate?.dismissed(controller: self)
    }
    
    @objc func shutterButtonTapped() {
        shutterButton.takePhoto()
        guard let camera = self.camera else {
            return
        }
        camera.captureStillImage()
    }
    
    @objc func shutterButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard let camera = self.camera else {
            return
        }
        switch sender.state {
        case .began:
            if recordsVideo && !camera.recordingVideo {
                shutterButton.startRecordingVideo()
                camera.startVideoRecording()
                feedbackGenerator.startRecordingVideoFeedback()
            }
            break
        case .ended:
            if recordsVideo && camera.recordingVideo {
                shutterButton.stopRecordingVideo()
                camera.stopVideoRecording()
                feedbackGenerator.endRecordingVideoFeedback()
            } else {
                feedbackGenerator.errorFeedback()
            }
            break
        default:
            break
        }
    }
    
    @objc func switchButtonTapped() {
        switch self.position {
        case .back:
            self.position = .front
            break
        default:
            self.position = .back
            break
        }
    }
    
    @objc func torchButtonTapped() {
        guard let camera = self.camera else {
            return
        }
        camera.torchState = !camera.torchState
    }
}

// MARK: GestureRecognizer Delegate Methods

extension LuminaViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
            beginZoomScale = currentZoomScale
        }
        return true
    }
}

// MARK: Tap to Focus Methods

extension LuminaViewController {
    func focusCamera(at point: CGPoint) {
        if self.isUpdating == true {
            return
        } else {
            self.isUpdating = true
        }
        let focusX = point.x/UIScreen.main.bounds.size.width
        let focusY = point.y/UIScreen.main.bounds.size.height
        guard let camera = self.camera else {
            return
        }
        camera.handleFocus(at: CGPoint(x: focusX, y: focusY))
        showFocusView(at: point)
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            camera.resetCameraToContinuousExposureAndFocus()
        }
    }
    
    private func showFocusView(at: CGPoint) {
        let focusView: UIImageView = UIImageView(image: UIImage(named: "cameraFocus", in: Bundle(for: LuminaViewController.self), compatibleWith: nil))
        focusView.contentMode = .scaleAspectFit
        focusView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        focusView.center = at
        focusView.alpha = 0.0
        self.view.addSubview(focusView)
        UIView.animate(withDuration: 0.2, animations: {
            focusView.alpha = 1.0
        }, completion: { complete in
            UIView.animate(withDuration: 1.0, animations: {
                focusView.alpha = 0.0
            }, completion: { final in
                focusView.removeFromSuperview()
                self.isUpdating = false
            })
        })
    }
}
