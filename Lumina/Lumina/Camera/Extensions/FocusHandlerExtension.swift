//
//  FocusHandlerExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

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
                LuminaLogger.error(message: "Trying to focus, but cannot detect device input!")
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
            LuminaLogger.error(message: "could not reset to continuous auto focus and exposure!!")
        }
    }
}
