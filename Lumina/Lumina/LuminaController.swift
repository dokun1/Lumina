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
    @available(iOS 10.2, *) case telephoto = "Telephoto"
    @available(iOS 10.2, *) case dual = "Dual"
}

public final class LuminaController: UIViewController {
    private var sessionPreset: String?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var previewView: UIView?
    
    private var metadataOutput: AVCaptureMetadataOutput?
    private var videoBufferQueue = DispatchQueue(label: "com.lumina.videoBufferQueue")
    private var metadataBufferQueue = DispatchQueue(label: "com.lumina.metadataBufferQueue")
    
    fileprivate var input: AVCaptureDeviceInput?
    
    fileprivate var videoOutput: AVCaptureVideoDataOutput {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: videoBufferQueue)
        return videoOutput
    }
    
    fileprivate var textPromptView: LuminaTextPromptView?
    fileprivate var initialPrompt: String?
    
    fileprivate var session: AVCaptureSession?
    
    fileprivate var cameraSwitchButton: UIButton?
    fileprivate var cameraCancelButton: UIButton?
    fileprivate var cameraTorchButton: UIButton?
    fileprivate var currentCameraDirection: CameraDirection = .back
    fileprivate var isUpdating = false
    fileprivate var torchOn = false
    
    
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
    
    public convenience init?(camera: CameraDirection, initialPrompt: String?) {
        self.init(camera: camera)
        self.initialPrompt = initialPrompt
        createTextPromptView()
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
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddInput(self.input) {
            session.addInput(self.input)
        }
        
        if session.canAddOutput(self.videoOutput) {
            session.addOutput(self.videoOutput)
        }
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        }
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataBufferQueue)
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
        
        self.metadataOutput = metadataOutput
        
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
        
        let image = UIImage(named: "cameraSwitchIcon", in: Bundle(for: LuminaController.self), compatibleWith: nil)
        cameraSwitchButton.setImage(image, for: .normal)
        
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
        
        let cameraTorchButton = UIButton(frame: CGRect(origin: CGPoint(x: self.view.frame.minX + 10, y: self.view.frame.minY + 10), size: CGSize(width: 50, height: 50)))
        cameraTorchButton.backgroundColor = UIColor.clear
        cameraTorchButton.addTarget(self, action: #selector(cameraTorchButtonTapped), for: UIControlEvents.touchUpInside)
        let torchImage = UIImage(named: "cameraTorch", in: Bundle(for: LuminaController.self), compatibleWith: nil)
        cameraTorchButton.setImage(torchImage, for: .normal)
        self.view.addSubview(cameraTorchButton)
        self.cameraTorchButton = cameraTorchButton
    }
    
    public required init?(coder aDecoder: NSCoder) {
        return nil
    }
}

extension LuminaController { // MARK: Text prompt methods
    fileprivate func createTextPromptView() {
        let view = LuminaTextPromptView(frame: CGRect(origin: CGPoint(x: self.view.bounds.minX + 10, y: self.view.bounds.minY + 70), size: CGSize(width: self.view.bounds.size.width - 20, height: 80)))
        if let prompt = self.initialPrompt {
            view.updateText(to: prompt)
        }
        self.view.addSubview(view)
        self.textPromptView = view
    }
    
    public func updateTextPromptView(to text:String) {
        guard let view = self.textPromptView else {
            print("No text prompt view to update!!")
            return
        }
        view.updateText(to: text)
    }
}

private extension LuminaController { //MARK: Button Tap Methods
    @objc func cameraSwitchButtonTapped() {
        if let cameraSwitchButton = self.cameraSwitchButton {
            cameraSwitchButton.isEnabled = false
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
            case .telephoto:
                commitSession(for: .front)
                break
            case .dual:
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
    
    @objc func cameraTorchButtonTapped() {
        guard let input = self.input else {
            print("Trying to update torch, but cannot detect device input!")
            return
        }
        if self.torchOn == false {
            do {
                if input.device.isTorchModeSupported(.on) {
                    try input.device.lockForConfiguration()
                    try input.device.setTorchModeOnWithLevel(1.0)
                    self.torchOn = !self.torchOn
                    input.device.unlockForConfiguration()
                }
            } catch {
                print("Could not turn torch on!!")
            }
        } else {
            do {
                if input.device.isTorchModeSupported(.off) {
                    try input.device.lockForConfiguration()
                    input.device.torchMode = .off
                    self.torchOn = !self.torchOn
                    input.device.unlockForConfiguration()
                }
            } catch {
                print("Could not turn torch off!!")
            }
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
        return UIImage(cgImage: graphicsImage, scale: 1.0, orientation: .right).fixOrientation
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
                
                return UIImage(cgImage: sample, scale: 1.0, orientation: .right).fixOrientation
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

extension LuminaController { // MARK: Tap to focus methods
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.isUpdating == true {
            return
        } else {
            self.isUpdating = true
        }
        for touch in touches {
            let point = touch.location(in: touch.view)
            let focusX = point.x/UIScreen.main.bounds.size.width
            let focusY = point.y/UIScreen.main.bounds.size.height
            guard let input = self.input else {
                print("Trying to focus, but cannot detect device input!")
                return
            }
            do {
                if input.device.isFocusModeSupported(.autoFocus) && input.device.isFocusPointOfInterestSupported {
                    try input.device.lockForConfiguration()
                    input.device.focusMode = .autoFocus
                    input.device.focusPointOfInterest = CGPoint(x: focusX, y: focusY)
                    if input.device.isExposureModeSupported(.autoExpose) && input.device.isExposurePointOfInterestSupported {
                        input.device.exposureMode = .autoExpose
                        input.device.exposurePointOfInterest = CGPoint(x: focusX, y: focusY)
                    }
                    input.device.unlockForConfiguration()
                    showFocusView(at: point)
                    let deadlineTime = DispatchTime.now() + .seconds(3)
                    DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                        self.resetCameraToContinuousExposureAndFocus()
                    }
                } else {
                    self.isUpdating = false
                }
            } catch {
                print("could not lock for configuration! Not able to focus")
                self.isUpdating = false
            }
        }
    }
    
    func resetCameraToContinuousExposureAndFocus() {
        do {
            guard let input = self.input else {
                print("Trying to focus, but cannot detect device input!")
                return
            }
            if input.device.isFocusModeSupported(.continuousAutoFocus) {
                try input.device.lockForConfiguration()
                input.device.focusMode = .continuousAutoFocus
                if input.device.isExposureModeSupported(.continuousAutoExposure) {
                    input.device.exposureMode = .continuousAutoExposure
                }
                input.device.unlockForConfiguration()
            }
        } catch {
            print("could not reset to continuous auto focus and exposure!!")
        }
    }
    
    func showFocusView(at: CGPoint) {
        let focusView: UIImageView = UIImageView(image: UIImage(named: "cameraFocus", in: Bundle(for: LuminaController.self), compatibleWith: nil))
        focusView.contentMode = .scaleAspectFit
        focusView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        focusView.center = at
        focusView.alpha = 0.0
        self.view.addSubview(focusView)
        UIView.animate(withDuration: 0.2, animations: {
            focusView.alpha = 1.0
        }, completion: { complete in
            UIView.animate(withDuration: 1.0, animations: {
                focusView.alpha = 0.0
            }, completion: { final in
                focusView.removeFromSuperview()
                self.isUpdating = false
            })
        })
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

private extension UIImage {
    var fixOrientation: UIImage {
        if imageOrientation == UIImageOrientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case UIImageOrientation.down, UIImageOrientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case UIImageOrientation.left, UIImageOrientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
            break
        case UIImageOrientation.right, UIImageOrientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2)
            break
        case UIImageOrientation.up, UIImageOrientation.upMirrored:
            break
        }
        
        switch imageOrientation {
        case UIImageOrientation.upMirrored, UIImageOrientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImageOrientation.leftMirrored, UIImageOrientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImageOrientation.up, UIImageOrientation.down, UIImageOrientation.left, UIImageOrientation.right:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil,
                                       width: Int(size.width),
                                       height: Int(size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent,
                                       bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImageOrientation.left, UIImageOrientation.leftMirrored, UIImageOrientation.right, UIImageOrientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }
}
