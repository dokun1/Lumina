//
//  CameraViewController.swift
//  CameraFramework
//
//  Created by David Okun IBM on 8/29/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import AVFoundation

public protocol LuminaDelegate {
    func detected(controller: LuminaViewController, stillImage: UIImage)
    func detected(controller: LuminaViewController, videoFrame: UIImage)
    func detected(controller: LuminaViewController, metadata: [Any])
    func cancelled(controller: LuminaViewController)
}

public enum CameraPosition {
    case front
    case back
    case unspecified
}

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
    
    open var delegate: LuminaDelegate! = nil
    
    open var position: CameraPosition = .unspecified {
        didSet {
            guard let camera = self.camera else {
                return
            }
            camera.position = position
        }
    }
    
    open var streamFrames = false {
        didSet {
            if let camera = self.camera {
                camera.streamFrames = streamFrames
            }
        }
    }
    
    open var trackMetadata = false {
        didSet {
            if let camera = self.camera {
                camera.trackMetadata = trackMetadata
            }
        }
    }
    
    open var textPrompt = "" {
        didSet {
            self.textPromptView.updateText(to: textPrompt)
        }
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        let camera = LuminaCamera(with: self)
        camera.delegate = self
        self.camera = camera
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let camera = LuminaCamera(with: self)
        camera.delegate = self
        self.camera = camera
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Camera framework is overloading on memory")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let camera = self.camera {
            camera.update()
            createUI()
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        if let camera = self.camera {
            camera.pause()
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateUI(orientation: UIApplication.shared.statusBarOrientation)
        updateButtonFrames()
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
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
        self.textPromptView.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + 95)
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

