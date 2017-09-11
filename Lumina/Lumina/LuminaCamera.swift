//
//  LuminaCamera.swift
//  Lumina
//
//  Created by David Okun IBM on 9/10/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import AVFoundation

protocol LuminaCameraDelegate {
    func finishedUpdating()
}

final class LuminaCamera: NSObject {
    var controller: LuminaViewController?
    fileprivate var delegate: LuminaCameraDelegate?
    
    var position: CameraDirection = .unspecified {
        didSet {
            if self.session.isRunning {
                self.session.stopRunning()
            }
            do {
                try update()
            } catch {
                print("could not update camera position")
            }
        }
    }
    
    required init(with controller: LuminaViewController) {
        self.controller = controller
    }
    
    fileprivate var session = AVCaptureSession()
    fileprivate var discoverySession: AVCaptureDevice.DiscoverySession? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
    }
    
    fileprivate var videoInput: AVCaptureDeviceInput?
    fileprivate var videoOutput = AVCaptureVideoDataOutput()
    
    private var _previewLayer: AVCaptureVideoPreviewLayer?
    var previewLayer: AVCaptureVideoPreviewLayer? {
        get {
            if let existingLayer = self._previewLayer {
                return existingLayer
            }
            guard let controller = self.controller else {
                return nil
            }
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            previewLayer.frame = controller.view.bounds
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            _previewLayer = previewLayer
            return previewLayer
        }
    }
    
    func update() throws {
        if let currentInput = self.videoInput {
            self.session.removeInput(currentInput)
            self.session.removeOutput(self.videoOutput)
        }
        do {
            guard let device = getDevice(with: self.position == .front ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back) else {
                print("could not find valid AVCaptureDevice")
                return
            }
            let input = try AVCaptureDeviceInput(device: device)
            if self.session.canAddInput(input) && self.session.canAddOutput(self.videoOutput) {
                self.videoInput = input
                self.session.addInput(input)
                self.session.addOutput(self.videoOutput)
                self.session.commitConfiguration()
                self.session.startRunning()
                if let delegate = self.delegate {
                    delegate.finishedUpdating()
                }
            } else {
                print("could not add input")
            }
        } catch {
            // TODO: add error handling here.
        }
    }
    
    private func getDevice(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        guard let discoverySession = self.discoverySession else {
            return nil
        }
        for device in discoverySession.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
}
