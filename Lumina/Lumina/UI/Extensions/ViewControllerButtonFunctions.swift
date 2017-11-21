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
                feedbackGenerator.startRecordingVideoFeedback()
            }
        case .ended:
            if recordsVideo && camera.recordingVideo {
                shutterButton.stopRecordingVideo()
                camera.stopVideoRecording()
                feedbackGenerator.endRecordingVideoFeedback()
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
        default:
            self.position = .back
        }
    }

    @objc func torchButtonTapped() {
        guard let camera = self.camera else {
            return
        }
        camera.torchState = !camera.torchState
    }
}
