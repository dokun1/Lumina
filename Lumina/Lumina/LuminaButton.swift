//
//  LuminaButton.swift
//  Lumina
//
//  Created by David Okun IBM on 9/11/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit

enum SystemButtonType {
    case torch
    case cameraSwitch
    case photoCapture
    case cancel
    case shutter
}

final class LuminaButton: UIButton {
    private var squareSystemButtonWidth = 40
    private var squareSystemButtonHeight = 40
    private var cancelButtonWidth = 70
    private var cancelButtonHeight = 30
    private var shutterButtonDimension = 70
    
    private var _image: UIImage?
    var image: UIImage? {
        get {
            return _image
        }
        set {
            self.setImage(newValue, for: UIControlState.normal)
            _image = newValue
        }
    }

    private var _text: String?
    var text: String? {
        get {
                return _text
        }
        set {
            self.setTitle(newValue, for: UIControlState.normal)
            _text = newValue
        }
    }
    
    required init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
        if let titleLabel = self.titleLabel {
            titleLabel.textColor = UIColor.white
            titleLabel.font = UIFont.systemFont(ofSize: 20)
        }
    }
    
    init(with systemStyle: SystemButtonType) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
        if let titleLabel = self.titleLabel {
            titleLabel.textColor = UIColor.white
            titleLabel.font = UIFont.systemFont(ofSize: 20)
        }
        switch systemStyle {
        case .torch:
            self.image = UIImage(named: "cameraTorch", in: Bundle(for: LuminaViewController.self), compatibleWith: nil)
            self.frame = CGRect(origin: CGPoint(x: 10, y: 10), size: CGSize(width: self.squareSystemButtonWidth, height: self.squareSystemButtonHeight))
            break
        case .cameraSwitch:
            self.image = UIImage(named: "cameraSwitch", in: Bundle(for: LuminaViewController.self), compatibleWith: nil)
            self.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.maxX - 50, y: 10), size: CGSize(width: self.squareSystemButtonWidth, height: self.squareSystemButtonHeight))
            break
        case .cancel:
            self.text = "Cancel"
            self.frame = CGRect(origin: CGPoint(x: 10, y: UIScreen.main.bounds.maxY - 50), size: CGSize(width: self.cancelButtonWidth, height: self.cancelButtonHeight))
            break
        case .shutter:
            self.image = UIImage(named: "cameraShutter", in: Bundle(for: LuminaViewController.self), compatibleWith: nil)
            self.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.midX - 35, y: UIScreen.main.bounds.maxY - 80), size: CGSize(width: self.shutterButtonDimension, height: self.shutterButtonDimension))
            break
        default:
            break
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
