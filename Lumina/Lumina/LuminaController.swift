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
    func detected(camera: LuminaController, image: UIImage)
    func detected(camera: LuminaController, data: [Any])
    func cancelled(camera: LuminaController)
}

public enum CameraDirection {
    case front
    case back
}

public final class LuminaController: UIViewController {
    private var sessionPreset: String?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var previewView: UIView?
    private var input: AVCaptureDeviceInput?
    
    private var videoOutput: AVCaptureVideoDataOutput {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoBufferQueue)
        return videoOutput
    }
    
    private var metadataOutput: AVCaptureMetadataOutput {
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataBufferQueue)
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
        metadataOutput.rectOfInterest = self.view.frame
        return metadataOutput
    }
    
    private var videoBufferQueue = DispatchQueue(label: "com.lumina.videoBufferQueue")
    private var metadataBufferQueue = DispatchQueue(label: "com.lumina.metadataBufferQueue")
    
    fileprivate var session: AVCaptureSession?
    
    fileprivate var cameraSwitchButton: UIButton?
    fileprivate var cameraCancelButton: UIButton?
    fileprivate var currentCameraDirection: CameraDirection = .back
    
    public var delegate: LuminaDelegate! = nil
    public var trackImages = false
    public var trackMetadata = false
    
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
            }
        }
        return device
    }
    
    public init?(camera: CameraDirection) {
        super.init(nibName: nil, bundle: nil)
        self.session = AVCaptureSession()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.previewView = self.view
        
        guard let previewLayer = self.previewLayer else {
            return
        }
        
        self.view.layer.addSublayer(previewLayer)
        self.view.bounds = UIScreen.main.bounds
        
        previewLayer.frame = self.view.bounds
        commitSession(for: camera)
        createUI()
    }
    
    fileprivate func commitSession(for desiredCameraDirection: CameraDirection) {
        guard let session = self.session else {
            return
        }
        self.currentCameraDirection = desiredCameraDirection
        
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        if let input = self.input {
            session.removeInput(input)
        }
        
        do {
            try self.input = AVCaptureDeviceInput(device: getDevice(for: desiredCameraDirection))
        } catch {
            return
        }
        
        if session.canAddInput(self.input) {
            session.addInput(self.input)
        }
        
        if session.canAddOutput(self.videoOutput) {
            session.addOutput(self.videoOutput)
        }
        
        if session.canAddOutput(self.metadataOutput) {
            session.addOutput(self.metadataOutput)
        }
        
        session.commitConfiguration()
        session.startRunning()
        guard let cameraSwitchButton = self.cameraSwitchButton else {
            return
        }
        cameraSwitchButton.isEnabled = true
    }
    
    private func createUI() {
        self.cameraSwitchButton = UIButton(frame: CGRect(x: self.view.frame.maxX - 60, y: self.view.frame.minY + 10, width: 50, height: 50))
        guard let cameraSwitchButton = self.cameraSwitchButton else {
            return
        }
        cameraSwitchButton.backgroundColor = UIColor.green
        cameraSwitchButton.addTarget(self, action: #selector(cameraSwitchButtonTapped), for: UIControlEvents.touchUpInside)
        self.view.addSubview(cameraSwitchButton)
        
        self.cameraCancelButton = UIButton(frame: CGRect(origin: CGPoint(x: self.view.frame.minX + 10, y: self.view.frame.maxY - 40), size: CGSize(width: 70, height: 30)))
        guard let cameraCancelButton = self.cameraCancelButton else {
            return
        }
        cameraCancelButton.setTitle("Cancel", for: .normal)
        cameraCancelButton.backgroundColor = UIColor.clear
        guard let titleLabel = cameraCancelButton.titleLabel else {
            return
        }
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: 0.5)
        cameraCancelButton.addTarget(self, action: #selector(cameraCancelButtonTapped), for: UIControlEvents.touchUpInside)
        self.view.addSubview(cameraCancelButton)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        return nil
    }
}

private extension LuminaController { //MARK: Button Tap Methods
    @objc func cameraSwitchButtonTapped() {
        if let cameraSwitchButton = self.cameraSwitchButton {
            cameraSwitchButton.isEnabled = false
            print("camera switch button tapped")
            if let session = self.session {
                session.stopRunning()
            }
            switch self.currentCameraDirection {
            case .front:
                commitSession(for: .back)
                break
            case .back:
                commitSession(for: .front)
                break
            }
        } else {
            print("camera switch button not found!!!")
        }
    }
    
    @objc func cameraCancelButtonTapped() {
        if let delegate = self.delegate {
            delegate.cancelled(camera: self)
        }
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
//        guard case self.trackImages = true else {
//            return
//        }
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            return
//        }
//        if CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0)) == kCVReturnSuccess {
//            var colorSpace: CGColorSpace? = nil
//            var bitmapInfo: CGBitmapInfo? = nil
//            var width: size_t = 0
//            var height: size_t = 0
//            var bitsPerComponent: size_t = 0
//            var bytesPerRow: size_t = 0
//            var data: UnsafeMutableRawPointer? = nil
//            
//            let format = CVPixelBufferGetPixelFormatType(imageBuffer)
//            if format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
//                data = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
//                width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
//                height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
//                bitsPerComponent = 1
//                bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
//                colorSpace = CGColorSpaceCreateDeviceGray()
//                bitmapInfo = cgbitmapinto
//            }
//        }
        guard let sampleBuffer = sampleBuffer else {
            return
        }
        guard let image = sampleBuffer.image else {
            return
        }
        guard let delegate = self.delegate else {
            return
        }
        delegate.detected(camera: self, image: image)
    }
}

extension LuminaController: AVCaptureMetadataOutputObjectsDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        guard case self.trackMetadata = true else {
            return
        }
        guard let delegate = self.delegate else {
            return
        }
        delegate.detected(camera: self, data: metadataObjects)
    }
}
