//
//  ViewControllerButtonFunctions.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation

extension LuminaViewController {
    @objc func cancelButtonTapped() {
        Log.verbose("cancel button tapped")
        delegate?.dismissed(controller: self)
    }

    @objc func shutterButtonTapped() {
        Log.verbose("shutter button tapped")
        shutterButton.takePhoto()
        previewLayer.opacity = 0
        UIView.animate(withDuration: 0.25) {
            self.previewLayer.opacity = 1
        }
        guard let camera = self.camera else {
            return
        }
        camera.captureStillImage()
    }

    @objc func shutterButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        Log.verbose("shutter button long pressed")
        guard let camera = self.camera else {
            return
        }
        switch sender.state {
        case .began:
            if recordsVideo && !camera.recordingVideo {
                Log.verbose("Attempting to start recording video")
                shutterButton.startRecordingVideo()
                camera.startVideoRecording()
            }
        case .ended:
            if recordsVideo && camera.recordingVideo {
                Log.verbose("Attempting to stop recording video")
                shutterButton.stopRecordingVideo()
                camera.stopVideoRecording()
            } else {
                Log.error("Cannot record video")
                feedbackGenerator.errorFeedback()
            }
        default:
            break
        }
    }

    @objc func switchButtonTapped() {
        Log.verbose("camera switch button tapped")
        switch self.position {
        case .back:
            self.position = .front
            torchButtonTapped()
        default:
            self.position = .back
        }
    }

    @objc func torchButtonTapped() {
        Log.verbose("torch button tapped")
        guard let camera = self.camera, self.position == .back else {
            Log.verbose("camera not found, or on front camera - defaulting to off")
            self.camera?.torchState = .off
            self.torchButton.updateTorchIcon(to: SystemButtonType.FlashState.off)
            return
        }
        switch camera.torchState {
        case .off:
            Log.verbose("torch mode should be set to on")
            camera.torchState = .on(intensity: 1.0)
            self.torchButton.updateTorchIcon(to: SystemButtonType.FlashState.on)
        //swiftlint:disable empty_enum_arguments
        case .on(_):
            Log.verbose("torch mode should be set to auto")
            camera.torchState = .auto
            self.torchButton.updateTorchIcon(to: SystemButtonType.FlashState.auto)
        case .auto:
            Log.verbose("torch mode should be set to off")
            camera.torchState = .off
            self.torchButton.updateTorchIcon(to: SystemButtonType.FlashState.off)
        }
    }
}
