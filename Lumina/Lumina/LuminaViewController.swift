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
public protocol LuminaDelegate {
    
    /// Triggered whenever a still image is captured by the user of Lumina
    ///
    /// - Parameters:
    ///   - controller: the instance of Lumina that captured the still image
    ///   - stillImage: the image captured by Lumina
    func detected(controller: LuminaViewController, stillImage: UIImage)
    
    /// Triggered whenever streamFrames is set to true on Lumina, and streams video frames as UIImage instances
    ///
    /// - Note: Will not be triggered unless streamFrames is true. False is default value
    /// - Parameters:
    ///   - controller: the instance of Lumina that is streaming the frames
    ///   - videoFrame: the frame captured by Lumina
    func detected(controller: LuminaViewController, videoFrame: UIImage)
    
    /// Triggered whenever a CoreML model is given to Lumina, and Lumina streams a video frame alongside a prediction
    ///
    /// - Note: Will not be triggered unless streamingModel resolves to not nil. Leaving the streamingModel parameter unset will not trigger this method
    /// - Warning: The other method for passing video frames back via a delegate will not be triggered in the presence of a CoreML model
    /// - Parameters:
    ///   - controller: the instance of Lumina that is streaming the frames
    ///   - videoFrame: the frame captured by Lumina
    ///   - predictions: the predictions made by the model used with Lumina
    func detected(controller: LuminaViewController, videoFrame: UIImage, predictions: [LuminaPrediction]?)
    
    /// Triggered whenever trackMetadata is set to true on Lumina, and streams metadata detected in the form of QR codes, bar codes, or faces
    ///
    /// - Note: For list of all machine readable object types, aside from QR codes or faces, click [here](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject/machine_readable_object_types).
    ///
    /// - Warning: Objects returned in array must be casted to AVMetadataObject or AVMetadataFaceObject individually.
    ///
    /// - Parameters:
    ///   - controller: the instance of Lumina that is streaming the metadata
    ///   - metadata: the array of metadata that is captured.
    func detected(controller: LuminaViewController, metadata: [Any])
    
    /// Triggered whenever the cancel button is tapped on Lumina.
    ///
    /// - Note: This is most usually used whenever
    ///
    /// - Parameter controller: the instance of Lumina that cancel was tapped on
    func cancelled(controller: LuminaViewController)
}

/// The position of the camera that is active on Lumina
public enum CameraPosition {
    /// the front facing camera of the iOS device
    case front
    /// the back (and usually main) facing camera of the iOS device
    case back
    /// a use case for letting Lumina decide which camera to use, and default is back
    case unspecified
}

/// The resolution to set the camera to at any time - refer to AVCaptureSession.Preset definitions for matching, closest as of iOS 11
public enum CameraResolution {
    case low352x288
    case vga640x480
    case medium1280x720
    case high1920x1080
    case ultra3840x2160
    case iframe1280x720
    case iframe960x540
    case photo
    case lowest
    case medium
    case highest
    case inputPriority
    
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
        _previewLayer = layer
        return layer
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
        button.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
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
    open var delegate: LuminaDelegate! = nil
    
    /// The position of the camera
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    open var position: CameraPosition = .unspecified {
        didSet {
            guard let camera = self.camera else {
                return
            }
            camera.position = position
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
    public var streamingModel: MLModel? {
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
    
    /// run this in order to create Lumina
    public init() {
        super.init(nibName: nil, bundle: nil)
        let camera = LuminaCamera(with: self)
        camera.delegate = self
        self.camera = camera
    }
    
    /// run this in order to create Lumina with a storyboard
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let camera = LuminaCamera(with: self)
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
            do {
                try camera.update()
                enableUI(valid: true)
            } catch CameraError.PermissionDenied {
                self.textPrompt = "Camera permissions for Lumina have been previously denied - please access your privacy settings to change this."
            } catch CameraError.PermissionRestricted {
                self.textPrompt = "Camera permissions for Lumina have been restricted - please access your privacy settings to change this."
            } catch CameraError.RequiresAuthorization {
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { success in
                    if success {
                        self.enableUI(valid: true)
                        try! camera.update()
                    } else {
                        self.textPrompt = "Camera permissions for Lumina have been previously denied - please access your privacy settings to change this."
                    }
                })
            } catch CameraError.Other(let reason){
                self.textPrompt = reason
            } catch CameraError.InvalidDevice {
                self.textPrompt = "Could not load desired camera device - please try again"
            } catch {
                self.textPrompt = "Unknown error occurred while loading Lumina - please try again"
            }
        }
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
    func createUI() {
        self.view.layer.addSublayer(self.previewLayer)
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.shutterButton)
        self.view.addSubview(self.switchButton)
        self.view.addSubview(self.torchButton)
        self.view.addSubview(self.textPromptView)
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
    func videoFrameCaptured(camera: LuminaCamera, frame: UIImage, predictedObjects: [LuminaPrediction]?) {
        if let delegate = self.delegate {
            delegate.detected(controller: self, videoFrame: frame, predictions: predictedObjects)
        }
    }
    
    func finishedFocus(camera: LuminaCamera) {
        self.isUpdating = false
    }
    
    func stillImageCaptured(camera: LuminaCamera, image: UIImage) {
        if let delegate = self.delegate {
            delegate.detected(controller: self, stillImage: image)
        }
    }
    
    func videoFrameCaptured(camera: LuminaCamera, frame: UIImage) {
        if let delegate = self.delegate {
            delegate.detected(controller: self, videoFrame: frame)
        }
    }
    
    func detected(camera: LuminaCamera, metadata: [Any]) {
        if let delegate = self.delegate {
            delegate.detected(controller: self, metadata: metadata)
        }
    }
    
    
}

// MARK: UIButton Functions

fileprivate extension LuminaViewController {
    @objc func cancelButtonTapped() {
        if let delegate = self.delegate {
            delegate.cancelled(controller: self)
        }
    }
    
    @objc func shutterButtonTapped() {
        guard let camera = self.camera else {
            return
        }
        camera.captureStillImage()
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

// MARK: Tap to Focus Methods

extension LuminaViewController {
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
    
    /// override with caution
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.isUpdating == true {
            return
        } else {
            self.isUpdating = true
        }
        for touch in touches {
            let point = touch.location(in: touch.view)
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
    }
}
