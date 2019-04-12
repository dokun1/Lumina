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

/// The main class that developers should interact with and instantiate when using Lumina
open class LuminaViewController: UIViewController {
    internal var logger = Logger(label: "com.okun.Lumina")
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

    var isUpdating = false

    /// The delegate for streaming output from Lumina
    weak open var delegate: LuminaDelegate?

    /// The position of the camera
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    open var position: CameraPosition = .back {
        didSet {
            LuminaLogger.notice(message: "Switching camera position to \(position.rawValue)")
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
            LuminaLogger.notice(message: "Setting video recording mode to \(recordsVideo)")
            self.camera?.recordsVideo = recordsVideo
            if recordsVideo {
                LuminaLogger.warning(message: "frames cannot be streamed, nor can CoreML be used via Lumina's recognizer mechanism")
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
            LuminaLogger.notice(message: "Setting frame streaming mode to \(streamFrames)")
            self.camera?.streamFrames = streamFrames
        }
    }

    /// Set this to choose whether or not Lumina will stream machine readable metadata through the delegate
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    ///
    /// - Warning: Will not do anything if delegate is not implemented
    open var trackMetadata = false {
        didSet {
            LuminaLogger.notice(message: "Setting metadata tracking mode to \(trackMetadata)")
            self.camera?.trackMetadata = trackMetadata
        }
    }

    /// Lumina comes ready with a view for a text prompt to give instructions to the user, and this is where you can set the text of that prompt
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    ///
    /// - Warning: If left empty, or unset, no view will be present, but view will be created if changed
    open var textPrompt = "" {
        didSet {
            LuminaLogger.notice(message: "Updating text prompt view to: \(textPrompt)")
            self.textPromptView.updateText(to: textPrompt)
        }
    }

    /// Set this to choose a resolution for the camera at any time - defaults to highest resolution possible for camera
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    open var resolution: CameraResolution = .highest {
        didSet {
            LuminaLogger.notice(message: "Updating camera resolution to \(resolution.rawValue)")
            self.camera?.resolution = resolution
        }
    }

    /// Set this to choose a frame rate for the camera at any time - defaults to 30 if query is not available
    ///
    /// - Note: Responds live to being set at any time, and will update automatically
    open var frameRate: Int = 30 {
        didSet {
            LuminaLogger.notice(message: "Attempting to update camera frame rate to \(frameRate) FPS")
            self.camera?.frameRate = frameRate
        }
    }

    /// Setting visibility of the buttons (default: all buttons are visible)
    public func setCancelButton(visible: Bool) {
        cancelButton.isHidden = !visible
    }

    public func setShutterButton(visible: Bool) {
        shutterButton.isHidden = !visible
    }

    public func setSwitchButton(visible: Bool) {
        switchButton.isHidden = !visible
    }

    public func setTorchButton(visible: Bool) {
        torchButton.isHidden = !visible
    }

    public func pauseCamera() {
        self.camera?.stop()
    }

    public func startCamera() {
        self.camera?.start()
    }

    /// A collection of model types that will be used when streaming images for object recognition
    ///
    /// - Note: Only works on iOS 11 and up
    ///
    /// - Warning: If this is set, streamFrames is over-ridden to true
    open var streamingModels: [AnyObject]? {
        didSet {
            if #available(iOS 11.0, *) {
                guard let streamingModels = self.streamingModels else {
                    return
                }
                var properlyCastModels = [LuminaModel]()
                for possibleModel in streamingModels {
                    guard let model = possibleModel as? LuminaModel else {
                        continue
                    }
                    properlyCastModels.append(model)
                }
                if properlyCastModels.count > 0 {
                    LuminaLogger.notice(message: "Valid models loaded - frame streaming mode defaulted to on")
                    self.streamFrames = true
                    self.camera?.streamingModels = properlyCastModels
                }
            } else {
                LuminaLogger.error(message: "Must be using iOS 11.0 or higher for CoreML")
            }
        }
    }

    /// The maximum amount of zoom that Lumina can use
    ///
    /// - Note: Default value will rely on whatever the active device can handle, if this is not explicitly set
    open var maxZoomScale: Float = MAXFLOAT {
        didSet {
            LuminaLogger.notice(message: "Max zoom scale set to \(maxZoomScale)x")
            self.camera?.maxZoomScale = maxZoomScale
        }
    }

    /// Set this to decide whether live photos will be captured whenever a still image is captured.
    ///
    /// - Note: Overrides cameraResolution to .photo
    ///
    /// - Warning: If video recording is enabled, live photos will not work.
    open var captureLivePhotos: Bool = false {
        didSet {
            LuminaLogger.notice(message: "Attempting to set live photo capture mode to \(captureLivePhotos)")
            self.camera?.captureLivePhotos = captureLivePhotos
        }
    }

    /// Set this to return AVDepthData with a still captured image
    ///
    /// - Note: Only works on iOS 11.0 or higher
    /// - Note: Only works with .photo, .medium1280x720, and .vga640x480 resolutions
    open var captureDepthData: Bool = false {
        didSet {
            LuminaLogger.notice(message: "Attempting to set depth data capture mode to \(captureDepthData)")
            self.camera?.captureDepthData = captureDepthData
        }
    }

    /// Set this to return AVDepthData with streamed video frames
    ///
    /// - Note: Only works on iOS 11.0 or higher
    /// - Note: Only works with .photo, .medium1280x720, and .vga640x480 resolutions
    open var streamDepthData: Bool = false {
        didSet {
            LuminaLogger.notice(message: "Attempting to set depth data streaming mode to \(streamDepthData)")
            self.camera?.streamDepthData = streamDepthData
        }
    }

    /// Set this to apply a level of logging to Lumina, to track activity within the framework
    public static var loggingLevel: Logger.Level = .critical {
        didSet {
            LuminaLogger.level = loggingLevel
        }
    }

    var currentZoomScale: Float = 1.0 {
        didSet {
            self.camera?.currentZoomScale = currentZoomScale
        }
    }

    var beginZoomScale: Float = 1.0

    /// run this in order to create Lumina
    public init() {
        super.init(nibName: nil, bundle: nil)
        let camera = LuminaCamera()
        camera.delegate = self
        self.camera = camera
        if let version = LuminaViewController.getVersion() {
            LuminaLogger.info(message: "Loading Lumina v\(version)")
        }
    }

    /// run this in order to create Lumina with a storyboard
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let camera = LuminaCamera()
        camera.delegate = self
        self.camera = camera
        if let version = LuminaViewController.getVersion() {
            LuminaLogger.info(message: "Loading Lumina v\(version)")
        }
    }

    /// override with caution
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        LuminaLogger.error(message: "Camera framework is overloading on memory")
    }

    /// override with caution
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        createUI()
        //updateUI(orientation: UIApplication.shared.statusBarOrientation)
        self.camera?.updateVideo({ result in
            self.handleCameraSetupResult(result)
        })
        if self.recordsVideo {
            self.camera?.updateAudio({ result in
                self.handleCameraSetupResult(result)
            })
        }
    }

    /// override with caution
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        feedbackGenerator.prepare()
    }

    open override var shouldAutorotate: Bool {
        guard let camera = self.camera else {
            return true
        }
        return !camera.recordingVideo
    }

    /// override with caution
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        self.camera?.stop()
    }

    /// override with caution
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if self.camera?.recordingVideo == true {
            return
        }
        updateUI(orientation: UIApplication.shared.statusBarOrientation)
        updateButtonFrames()
    }

    /// override with caution
    open override var prefersStatusBarHidden: Bool {
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
