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

public enum CameraDirection: String {
    case front = "Front"
    case back = "Back"
}

public final class LuminaController: UIViewController {
    private var sessionPreset: String?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var previewView: UIView?
    private var input: AVCaptureDeviceInput?
    
    private var videoOutput: AVCaptureVideoDataOutput {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: videoBufferQueue)
        return videoOutput
    }
    
    private var metadataOutput: AVCaptureMetadataOutput {
        let metadataOutput = AVCaptureMetadataOutput()
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
    public var improvedImageDetectionPerformance = false
    
    private var discoverySession: AVCaptureDeviceDiscoverySession? {
        let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInDualCamera, AVCaptureDeviceType.builtInTelephotoCamera, AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified)
        return discoverySession
    }
    
    private func getDevice(for cameraDirection: CameraDirection) -> AVCaptureDevice? {
        var device: AVCaptureDevice?
        guard let discoverySession = self.discoverySession else {
            print("Could not get discovery session")
            return nil
        }
        for discoveryDevice: AVCaptureDevice in discoverySession.devices {
            if cameraDirection == .front {
                if discoveryDevice.position == AVCaptureDevicePosition.front {
                    device = discoveryDevice
                    break
                }
            } else {
                if discoveryDevice.position == AVCaptureDevicePosition.back { // TODO: support for iPhone 7 plus dual cameras
                    device = discoveryDevice
                    break
                }
                
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
            print("Could not access image preview layer")
            return
        }
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(previewLayer)
        self.view.bounds = UIScreen.main.bounds
        
        previewLayer.frame = self.view.bounds
        commitSession(for: camera)
        createUI()
    }
    
    fileprivate func commitSession(for desiredCameraDirection: CameraDirection) {
        guard let session = self.session else {
            print("Error getting session")
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
            print("Error getting device input for \(desiredCameraDirection.rawValue)")
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
        
        self.metadataOutput.metadataObjectTypes = self.metadataOutput.availableMetadataObjectTypes
        self.metadataOutput.setMetadataObjectsDelegate(self, queue: metadataBufferQueue)
        
        session.commitConfiguration()
        session.startRunning()
        
        guard let cameraSwitchButton = self.cameraSwitchButton else {
            print("Could not create camera switch button")
            return
        }
        cameraSwitchButton.isEnabled = true
        
    }
    
    private func createUI() {
        self.cameraSwitchButton = UIButton(frame: CGRect(x: self.view.frame.maxX - 60, y: self.view.frame.minY + 10, width: 50, height: 50))
        guard let cameraSwitchButton = self.cameraSwitchButton else {
            print("Could not access camera switch button memory address")
            return
        }
        cameraSwitchButton.backgroundColor = UIColor.clear
        cameraSwitchButton.addTarget(self, action: #selector(cameraSwitchButtonTapped), for: UIControlEvents.touchUpInside)
        self.view.addSubview(cameraSwitchButton)
        
        cameraSwitchButton.setImage("cameraSwitchIcon".imageFromBundle, for: .normal)
        
        self.cameraCancelButton = UIButton(frame: CGRect(origin: CGPoint(x: self.view.frame.minX + 10, y: self.view.frame.maxY - 40), size: CGSize(width: 70, height: 30)))
        guard let cameraCancelButton = self.cameraCancelButton else {
            return
        }
        cameraCancelButton.setTitle("Cancel", for: .normal)
        cameraCancelButton.backgroundColor = UIColor.clear
        guard let titleLabel = cameraCancelButton.titleLabel else {
            print("Could not access cancel button label memory address")
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
    var imageFromCoreImage: UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
            print("Could not get image buffer from CMSampleBuffer")
            return nil
        }
        let coreImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let context: CIContext = CIContext()
        guard let graphicsImage: CGImage = context.createCGImage(coreImage, from: coreImage.extent) else {
            print("Could not create CoreGraphics image from context")
            return nil
        }
        return UIImage(cgImage: graphicsImage)
    }
    
    var imageFromPixelBuffer: UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
            print("Could not get image buffer from CMSampleBuffer")
            return nil
        }
        if CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0)) == kCVReturnSuccess {
            var colorSpace = CGColorSpaceCreateDeviceRGB()
            var bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
            var width = CVPixelBufferGetWidth(imageBuffer)
            var height = CVPixelBufferGetHeight(imageBuffer)
            var bitsPerComponent: size_t = 8
            var bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            var baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
            
            let format = CVPixelBufferGetPixelFormatType(imageBuffer)
            if format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
                width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
                height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
                bitsPerComponent = 1
                bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
                colorSpace = CGColorSpaceCreateDeviceGray()
                bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            }
            
            let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
            if let context = context {
                guard let sample = context.makeImage() else {
                    print("Could not create CoreGraphics image from context")
                    return nil
                }
                CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
                return UIImage(cgImage: sample)
            } else {
                print("Could not create CoreGraphics context")
                return nil
            }
        } else {
            print("Could not lock base address for pixel buffer")
            return nil
        }
    }
}

extension LuminaController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard case self.trackImages = true else {
            return
        }
        guard let delegate = self.delegate else {
            print("Warning!! No delegate set, but image tracking turned on")
            return
        }
        guard let sampleBuffer = sampleBuffer else {
            print("No sample buffer detected")
            return
        }
        var image: UIImage? = nil
        let startTime = Date()
        if self.improvedImageDetectionPerformance {
            image = sampleBuffer.imageFromPixelBuffer
        
        } else {
            image = sampleBuffer.imageFromCoreImage
        }
        let end = Date()
        print("Image tracking processing time: \(end.timeIntervalSince(startTime))")
        if let image = image {
            delegate.detected(camera: self, image: image)
        }
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

extension String {
    var imageFromBundle: UIImage? {
        let bundle = Bundle(for: LuminaController.self)
        if let path = bundle.path(forResource: self, ofType: "png") {
            return UIImage(contentsOfFile: path)
        } else {
            return nil
        }
    }
}
