//
//  ViewControllerFocusHandlerExtension.swift
//  Lumina
//
//  Created by David Okun on 11/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation

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
        LuminaLogger.notice(message: "Attempting focus at (\(focusX), \(focusY))")
        camera.handleFocus(at: CGPoint(x: focusX, y: focusY))
        showFocusView(at: point)
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            camera.resetCameraToContinuousExposureAndFocus()
        }
    }

    private func showFocusView(at point: CGPoint) {
        let focusView: UIImageView = UIImageView(image: UIImage(named: "cameraFocus", in: Bundle(for: LuminaViewController.self), compatibleWith: nil))
        focusView.contentMode = .scaleAspectFit
        focusView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        focusView.transform = CGAffineTransform(scaleX: 1.7, y: 1.7)
        focusView.center = point
        focusView.alpha = 0.0
        self.view.addSubview(focusView)
        UIView.animate(withDuration: 0.3, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: { _ in
            UIView.animate(withDuration: 1.0, animations: {
                focusView.alpha = 0.0
            }, completion: { _ in
                focusView.removeFromSuperview()
                self.isUpdating = false
            })
        })
    }
}
