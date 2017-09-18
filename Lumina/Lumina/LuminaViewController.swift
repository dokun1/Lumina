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
    func cancelButtonTapped(controller: LuminaViewController)
    func stillImageTaken(controller: LuminaViewController, image: UIImage)
    func videoFrameCaptured(controller: LuminaViewController, frame: UIImage)
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
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateUI(orientation: UIApplication.shared.statusBarOrientation)
        updateButtonFrames()
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
        self.shutterButton.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.maxY - 45)
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
    func stillImageCaptured(camera: LuminaCamera, image: UIImage) {
        if let delegate = self.delegate {
            delegate.stillImageTaken(controller: self, image: image)
        }
    }
    
    func videoFrameCaptured(camera: LuminaCamera, frame: UIImage) {
        if let delegate = self.delegate {
            delegate.videoFrameCaptured(controller: self, frame: frame)
        }
    }
}

// MARK: UIButton Functions

fileprivate extension LuminaViewController {
    @objc func cancelButtonTapped() {
        if let delegate = self.delegate {
            delegate.cancelButtonTapped(controller: self)
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
