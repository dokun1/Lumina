//
//  LuminaDeviceUtil.swift
//  Lumina
//
//  Created by David Okun on 10/20/17.
//  Copyright © 2017 David Okun. All rights reserved.
//
//  Thank you to Saoud M. Rizwan!
//  https://medium.com/@sdrzn/make-your-ios-app-feel-better-a-comprehensive-guide-over-taptic-engine-and-haptic-feedback-724dec425f10

import UIKit
import AudioToolbox.AudioServices

final class LuminaHapticFeedbackGenerator {
    private let notificationGeneratorSharedInstance = UINotificationFeedbackGenerator()

    func prepare() {
        notificationGeneratorSharedInstance.prepare()
    }

    func errorFeedback() {
        if UIDevice.current.hasHapticFeedback {
            notificationGeneratorSharedInstance.notificationOccurred(.warning)
        } else if UIDevice.current.hasTapticEngine {
            let tryAgain = SystemSoundID(1102)
            AudioServicesPlaySystemSound(tryAgain)
        }
    }
}

internal extension UIDevice {
    enum DevicePlatform {
        case other
        case iPhone6S
        case iPhone6SPlus
        case iPhone7
        case iPhone7Plus
        case iPhone8
        case iPhone8Plus
        case iPhoneX
        case iPhoneXS
        case iPhoneXSMax
        case iPhoneXR
        case simulator
    }

    static var hasNotch: Bool {
        return platform == .iPhoneXSMax ||
               platform == .iPhoneXS ||
               platform == .iPhoneXR ||
               platform == .iPhoneX
    }

    static var platform: DevicePlatform {
        var sysinfo = utsname()
        uname(&sysinfo)
        let platform = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        switch platform {
        case "x86_64":
            return .simulator
        case "iPhone11,2":
            return .iPhoneXS
        case "iPhone11,4", "iPhone11,6":
            return .iPhoneXSMax
        case "iPhone11,8":
            return .iPhoneXR
        case "iPhone10,1", "iPhone10,4":
            return .iPhone8
        case "iPhone10,2", "iPhone10,5":
            return .iPhone8Plus
        case "iPhone10,3", "iPhone10,6":
            return .iPhoneX
        case "iPhone9,2", "iPhone9,4":
            return .iPhone7Plus
        case "iPhone9,1", "iPhone9,3":
            return .iPhone7
        case "iPhone8,2":
            return .iPhone6SPlus
        case "iPhone8,1":
            return .iPhone6S
        default:
            return .other
        }
    }

    var hasTapticEngine: Bool {
        let platform = UIDevice.platform
        return platform == .iPhone6S || platform == .iPhone6SPlus || platform == .iPhone7 || platform == .iPhone7Plus || platform == .iPhone8 || platform == .iPhone8Plus || platform == .iPhoneX
    }

    var hasHapticFeedback: Bool {
        let platform = UIDevice.platform
        return platform == .iPhone7 || platform == .iPhone7Plus || platform == .iPhone8 || platform == .iPhone8Plus || platform == .iPhoneX
    }
}
