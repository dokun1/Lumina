//
//  LuminaController.swift
//  Lumina
//
//  Created by David Okun IBM on 4/21/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import Foundation
import AVFoundation

public protocol LuminaDelegate {
    func detected(image: UIImage)
    func detected(data: Data)
}

public enum CameraDirection {
    case front
    case back
    case dual
}

public final class LuminaController: UIViewController {
    private var sessionPreset: String?
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var previewView: UIView?
    private var input: AVCaptureDeviceInput?
    private var output: AVCaptureVideoDataOutput?
    private var bufferQueue = DispatchQueue(label: "com.lumina.bufferQueue")
    
    public var delegate: LuminaDelegate! = nil
    
    private var discoverySession: AVCaptureDeviceDiscoverySession? {
        let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInDualCamera, AVCaptureDeviceType.builtInTelephotoCamera, AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified)
        return discoverySession
    }
    
    private func getDevice(for cameraDirection: CameraDirection) -> AVCaptureDevice? {
        var device: AVCaptureDevice?
        guard let discoverySession = self.discoverySession else {
            return nil
        }
        for discoveryDevice: AVCaptureDevice in discoverySession.devices {
            switch cameraDirection {
            case .front:
                if discoveryDevice.position == AVCaptureDevicePosition.front {
                    device = discoveryDevice
                }
                break
            case .back:
                if discoveryDevice.position == AVCaptureDevicePosition.back {
                    device = discoveryDevice
                }
                break
            case .dual:
                print("Could not find discovery device to match!!!")
                break
            }
        }
        return device
    }
    
    public init?(camera: CameraDirection) {
        super.init(nibName: nil, bundle: nil)
        self.session = AVCaptureSession()
        guard let session = self.session else {
            return nil
        }
        session.sessionPreset = AVCaptureSessionPresetHigh
 
        self.previewView = self.view
        
        do {
            try self.input = AVCaptureDeviceInput(device: getDevice(for: camera))
            
        } catch {
            return nil
        }

        if session.canAddInput(self.input) {
            session.addInput(self.input)
        }
        
        self.output = AVCaptureVideoDataOutput()
        guard let output = self.output else {
            return nil
        }
        
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: bufferQueue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        guard let previewLayer = self.previewLayer else {
            return nil
        }
        self.view.layer.addSublayer(previewLayer)
        self.view.bounds = UIScreen.main.bounds
        
        previewLayer.frame = self.view.bounds
        session.startRunning()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        return nil
    }
}

private extension CMSampleBuffer {
    var image: UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
            return nil
        }
        let coreImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let context: CIContext = CIContext()
        guard let graphicsImage: CGImage = context.createCGImage(coreImage, from: coreImage.extent) else {
            return nil
        }
        let image = UIImage(cgImage: graphicsImage)
        return image.rotated(by: Measurement(value: 90.0, unit: .degrees))
    }
}

private extension UIImage {
    struct RotationOptions: OptionSet {
        let rawValue: Int
        
        static let flipOnVerticalAxis = RotationOptions(rawValue: 1)
        static let flipOnHorizontalAxis = RotationOptions(rawValue: 2)
    }
    
    func rotated(by rotationAngle: Measurement<UnitAngle>, options: RotationOptions = []) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let rotationInRadians = CGFloat(rotationAngle.converted(to: .radians).value)
        let transform = CGAffineTransform(rotationAngle: rotationInRadians)
        var rect = CGRect(origin: .zero, size: self.size).applying(transform)
        rect.origin = .zero
        
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { renderContext in
            renderContext.cgContext.translateBy(x: rect.midX, y: rect.midY)
            renderContext.cgContext.rotate(by: rotationInRadians)
            
            let x = options.contains(.flipOnVerticalAxis) ? -1.0 : 1.0
            let y = options.contains(.flipOnHorizontalAxis) ? 1.0 : -1.0
            renderContext.cgContext.scaleBy(x: CGFloat(x), y: CGFloat(y))
            
            let drawRect = CGRect(origin: CGPoint(x: -self.size.width/2, y: -self.size.height/2), size: self.size)
            renderContext.cgContext.draw(cgImage, in: drawRect)
        }
    }
}

extension LuminaController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let sampleBuffer = sampleBuffer else {
            return
        }
        guard let image = sampleBuffer.image else {
            return
        }
        guard let delegate = self.delegate else {
            return
        }
        delegate.detected(image: image)
    }
}
