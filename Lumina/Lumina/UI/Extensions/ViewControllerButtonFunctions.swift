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
        delegate?.dismissed(controller: self)
    }

    @objc func shutterButtonTapped() {
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
        guard let camera = self.camera else {
            return
        }
        switch sender.state {
        case .began:
            if recordsVideo && !camera.recordingVideo {
                shutterButton.startRecordingVideo()
                camera.startVideoRecording()
            }
        case .ended:
            if recordsVideo && camera.recordingVideo {
                shutterButton.stopRecordingVideo()
                camera.stopVideoRecording()
            } else {
                feedbackGenerator.errorFeedback()
            }
        default:
            break
        }
    }

    @objc func switchButtonTapped() {
        switch self.position {
        case .back:
            self.position = .front
            torchButtonTapped()
        default:
            self.position = .back
        }
    }

    @objc func torchButtonTapped() {
        print("torch button tapped")
        guard let camera = self.camera, self.position == .back else {
            print("camera not found, or on front camera - defaulting to off")
            self.camera?.torchState = .off
            self.torchButton.updateTorchIcon(to: SystemButtonType.FlashState.off)
            return
        }
        switch camera.torchState {
        case .off:
            print("torch mode should be set to on")
            camera.torchState = .on(intensity: 1.0)
            self.torchButton.updateTorchIcon(to: SystemButtonType.FlashState.on)
        //swiftlint:disable empty_enum_arguments
        case .on(_):
            print("torch mode should be set to auto")
            camera.torchState = .auto
            self.torchButton.updateTorchIcon(to: SystemButtonType.FlashState.auto)
        case .auto:
            print("torch mode should be set to off")
            camera.torchState = .off
            self.torchButton.updateTorchIcon(to: SystemButtonType.FlashState.off)
        }
    }
}
