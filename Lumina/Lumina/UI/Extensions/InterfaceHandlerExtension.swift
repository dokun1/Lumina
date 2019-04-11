//
//  InterfaceHandlerExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

extension LuminaViewController {
    @objc func handlePinchGestureRecognizer(recognizer: UIPinchGestureRecognizer) {
        guard self.position == .back else {
            return
        }
        currentZoomScale = min(maxZoomScale, max(1.0, beginZoomScale * Float(recognizer.scale)))
        LuminaLogger.notice(message: "setting zoom scale to \(currentZoomScale)")
    }

    @objc func handleTapGestureRecognizer(recognizer: UITapGestureRecognizer) {
        delegate?.tapped(at: recognizer.location(in: view), from: self)
        if position == .back {
            focusCamera(at: recognizer.location(in: view))
        }
    }

    func createUI() {
        LuminaLogger.notice(message: "Creating UI")
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
        LuminaLogger.notice(message: "updating UI for orientation: \(orientation.rawValue)")
        guard let connection = self.previewLayer.connection, connection.isVideoOrientationSupported else {
            return
        }
        self.previewLayer.frame = self.view.bounds
        connection.videoOrientation = necessaryVideoOrientation(for: orientation)
        self.camera?.updateOutputVideoOrientation(connection.videoOrientation)
    }

    func updateButtonFrames() {
        self.cancelButton.center = CGPoint(x: self.view.frame.minX + 55, y: self.view.frame.maxY - 45)
        var minY = self.view.frame.minY
        if self.view.frame.width > self.view.frame.height {
            var maxX = self.view.frame.maxX
            if #available(iOS 11, *) {
                maxX = self.view.safeAreaLayoutGuide.layoutFrame.maxX
            }
            self.shutterButton.center = CGPoint(x: maxX - 45, y: self.view.frame.midY)
        } else {
            var maxY = self.view.frame.maxY
            if #available(iOS 11, *) {
                maxY = self.view.safeAreaLayoutGuide.layoutFrame.maxY
                minY = self.view.safeAreaLayoutGuide.layoutFrame.minY
            }
            self.shutterButton.center = CGPoint(x: self.view.frame.midX, y: maxY - 45)
        }
        self.switchButton.center = CGPoint(x: self.view.frame.maxX - 30, y: self.view.frame.minY + (UIDevice.hasNotch ? 40 : 25))
        self.torchButton.center = CGPoint(x: self.view.frame.minX + 25, y: self.view.frame.minY + (UIDevice.hasNotch ? 40 : 25))
        /// Use more width, if text has been moved down below the buttons (e.g. notch on iPhone X):
        let textWidth = self.view.frame.maxX - (minY > 35 ? 20 : 110)
        self.textPromptView.frame.size = CGSize(width: textWidth - 10, height: 80)
        self.textPromptView.layoutSubviews()
        self.textPromptView.center = CGPoint(x: self.view.frame.midX, y: minY + 45)
    }

    // swiftlint:disable cyclomatic_complexity
    func handleCameraSetupResult(_ result: CameraSetupResult) {
        LuminaLogger.notice(message: "camera set up result: \(result.rawValue)")
        DispatchQueue.main.async {
            switch result {
            case .videoSuccess:
                if let camera = self.camera {
                    self.enableUI(valid: true)
                    self.updateUI(orientation: UIApplication.shared.statusBarOrientation)
                    camera.start()
                }
            case .audioSuccess:
                break
            case .requiresUpdate:
                self.camera?.updateVideo({ result in
                    self.handleCameraSetupResult(result)
                })
            case .videoPermissionDenied:
                self.textPrompt = "Camera permissions for Lumina have been previously denied - please access your privacy settings to change this."
            case .videoPermissionRestricted:
                self.textPrompt = "Camera permissions for Lumina have been restricted - please access your privacy settings to change this."
            case .videoRequiresAuthorization:
                self.camera?.requestVideoPermissions()
            case .audioPermissionRestricted:
                self.textPrompt = "Audio permissions for Lumina have been restricted - please access your privacy settings to change this."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.textPrompt = ""
                }
            case .audioRequiresAuthorization:
                self.camera?.requestAudioPermissions()
            case .audioPermissionDenied:
                self.textPrompt = "Audio permissions for Lumina have been previously denied - please access your privacy settings to change this."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.textPrompt = ""
                }
            case .invalidVideoDataOutput,
                 .invalidVideoInput,
                 .invalidPhotoOutput,
                 .invalidVideoMetadataOutput,
                 .invalidVideoFileOutput,
                 .invalidAudioInput,
                 .invalidDepthDataOutput:
                self.textPrompt = "\(result.rawValue) - please try again"
            case .unknownError:
                self.textPrompt = "Unknown error occurred while loading Lumina - please try again"
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
