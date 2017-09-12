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
    func detected(camera: LuminaViewController, image: UIImage)
    func detected(camera: LuminaViewController, data: [Any])
    func cancelled(camera: LuminaViewController)
}

public enum CameraDirection: String {
    case front = "Front"
    case back = "Back"
    case telephoto = "Telephoto"
    case dual = "Dual"
    case unspecified = "Unspecified"
}

public final class LuminaViewController: UIViewController {
    private var sessionPreset: String?
    
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    private var previewView: UIView?
    
    private var metadataOutput: AVCaptureMetadataOutput?
    private var videoBufferQueue = DispatchQueue(label: "com.lumina.videoBufferQueue")
    private var metadataBufferQueue = DispatchQueue(label: "com.lumina.metadataBufferQueue")
    
    fileprivate var input: AVCaptureDeviceInput?
    
    fileprivate var videoOutput: AVCaptureVideoDataOutput {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : kCVPixelFormatType_32BGRA]
        //videoOutput.setSampleBufferDelegate(self, queue: videoBufferQueue)
        return videoOutput
    }
    
    fileprivate var textPromptView: LuminaTextPromptView?
    fileprivate var initialPrompt: String?
    
    fileprivate var session: AVCaptureSession?
    
    private var _cameraSwitchButton: LuminaButton?
    fileprivate var cameraSwitchButton: LuminaButton {
        get {
            if let switchButton = _cameraSwitchButton {
                return switchButton
            }
            let button = LuminaButton(with: .cameraSwitch)
            button.addTarget(self, action: #selector(cameraSwitchButtonTapped), for: UIControlEvents.touchUpInside)
            _cameraSwitchButton = button
            return button
        }
    }
    
    private var _cameraCancelButton: LuminaButton?
    fileprivate var cameraCancelButton: LuminaButton {
        get {
            if let cancelButton = _cameraCancelButton {
                return cancelButton
            }
            let button = LuminaButton(with: .cancel)
            button.addTarget(self, action: #selector(cameraCancelButtonTapped), for: UIControlEvents.touchUpInside)
            _cameraCancelButton = button
            return button
        }
    }
    
    private var _cameraTorchButton: LuminaButton?
    fileprivate var cameraTorchButton: UIButton {
        get {
            if let torchButton = _cameraTorchButton {
                return torchButton
            }
            let button = LuminaButton(with: .torch)
            button.addTarget(self, action: #selector(cameraTorchButtonTapped), for: UIControlEvents.touchUpInside)
            _cameraTorchButton = button
            return button
        }
    }
    
    fileprivate var isUpdating = false
    fileprivate var torchOn = false
    fileprivate var metadataBordersCodes: [LuminaMetadataBorderView]?
    fileprivate var metadataBordersFaces: [LuminaMetadataBorderView]?
    fileprivate var metadataBordersCodesDestructionTimer: Timer?
    fileprivate var metadataBordersFacesDestructionTimer: Timer?
    fileprivate var camera: LuminaCamera?
    
    public var delegate: LuminaDelegate! = nil
    public var trackImages = false
    public var trackMetadata = false
    public var improvedImageDetectionPerformance = false
    public var drawMetadataBorders = false
    
    open var position: CameraDirection = .unspecified {
        didSet {
            guard let camera = self.camera else {
                return
            }
            if position == .unspecified {
                self.position = .back
            } else {
                camera.position = position
            }
        }
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
//    private var discoverySession: AVCaptureDevice.DiscoverySession? {
//        var deviceTypes: [AVCaptureDevice.DeviceType] = []
//        deviceTypes.append(AVCaptureDevice.DeviceType.builtInWideAngleCamera)
//        if #available(iOS 10.2, *) {
//            deviceTypes.append(AVCaptureDevice.DeviceType.builtInDualCamera)
//            deviceTypes.append(AVCaptureDevice.DeviceType.builtInTelephotoCamera)
//        }
//        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
//
//        return discoverySession
//    }
    
//    private func getDevice(for cameraDirection: CameraDirection) -> AVCaptureDevice? {
//        var device: AVCaptureDevice?
//        guard let discoverySession = self.discoverySession else {
//            print("Could not get discovery session")
//            return nil
//        }
//        for discoveryDevice: AVCaptureDevice in discoverySession.devices {
//            if cameraDirection == .front {
//                if discoveryDevice.position == AVCaptureDevice.Position.front {
//                    device = discoveryDevice
//                    break
//                }
//            } else {
//                if discoveryDevice.position == AVCaptureDevice.Position.back { // TODO: add support for iPhone 7 plus dual cameras
//                    device = discoveryDevice
//                    break
//                }
//            }
//        }
//        return device
//    }
    
//    public init?(camera: CameraDirection) {
//        super.init(nibName: nil, bundle: nil)
//
//        let session = AVCaptureSession()
//        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        self.previewView = self.view
//
//        guard let previewLayer = self.previewLayer else {
//            print("Could not access image preview layer")
//            return
//        }
//        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        self.view.layer.addSublayer(previewLayer)
//        self.view.bounds = UIScreen.main.bounds
//
//        previewLayer.frame = self.view.bounds
//        self.session = session
//        commitSession(for: camera)
//        createUI()
//        createTextPromptView()
//    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        let camera = LuminaCamera(with: self)
        camera.delegate = self
        self.camera = camera
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let camera = self.camera {
            createUI()
            do {
                try camera.update()
            }
            catch {
                print("could not update camera")
            }
        }
    }
    
//    fileprivate func commitSession(for desiredCameraDirection: CameraDirection) {
//        guard let session = self.session else {
//            print("Error getting session")
//            return
//        }
//        self.currentCameraDirection = desiredCameraDirection
//
//        session.sessionPreset = AVCaptureSession.Preset.high
//
//        if let input = self.input {
//            session.removeInput(input)
//        }
//
//        do {
//            guard let device = getDevice(for: desiredCameraDirection) else {
//                print("could not get desired camera direction")
//                return
//            }
//            try input = AVCaptureDeviceInput(device: device)
//            if session.canAddInput(input!) {
//                session.addInput(input!)
//                self.input = input!
//            }
//        } catch {
//            print("Error getting device input for \(desiredCameraDirection.rawValue)")
//            return
//        }
//
////        let metadataOutput = AVCaptureMetadataOutput()
//
//        let videoOutput = self.videoOutput
//
//        if session.canAddOutput(videoOutput) {
//            session.addOutput(videoOutput)
//        }
//
////        if session.canAddOutput(metadataOutput) {
////            session.addOutput(metadataOutput)
////        }
////        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataBufferQueue)
////        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
////
////        self.metadataOutput = metadataOutput
//
//        session.commitConfiguration()
//        session.startRunning()
//
//        if let connection = videoOutput.connection(with: AVMediaType.video) {
//            connection.isEnabled = true
//            if connection.isVideoMirroringSupported && desiredCameraDirection == .front {
//                connection.isVideoMirrored = true
//                connection.preferredVideoStabilizationMode = .standard
//            }
//        }
//
//        guard let cameraSwitchButton = self.cameraSwitchButton else {
//            print("Could not create camera switch button")
//            return
//        }
//        cameraSwitchButton.isEnabled = true
//
//    }
    
    private func createUI() {
        guard let camera = self.camera else {
            return
        }
        guard let previewLayer = camera.previewLayer else {
            return
        }
        self.previewLayer = previewLayer
        self.view.layer.addSublayer(previewLayer)
    
        self.view.addSubview(self.cameraSwitchButton)
        
        self.view.addSubview(self.cameraSwitchButton)
        self.view.addSubview(self.cameraCancelButton)
        self.view.addSubview(self.cameraTorchButton)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        return nil
    }
}

extension LuminaViewController: LuminaCameraDelegate { // MARK: Camera Delegate Functions
    func finishedUpdating() {
        self.cameraTorchButton.isEnabled = true
        self.cameraCancelButton.isEnabled = true
        self.cameraSwitchButton.isEnabled = true
    }
}

extension LuminaViewController { // MARK: Text prompt methods
    fileprivate func createTextPromptView() {
        let view = LuminaTextPromptView(frame: CGRect(origin: CGPoint(x: self.view.bounds.minX + 10, y: self.view.bounds.minY + 70), size: CGSize(width: self.view.bounds.size.width - 20, height: 80)))
        if let prompt = self.initialPrompt {
            view.updateText(to: prompt)
        }
        self.view.addSubview(view)
        self.textPromptView = view
    }
    
    public func updateTextPromptView(to text:String) {
        DispatchQueue.main.async {
            guard let view = self.textPromptView else {
                print("No text prompt view to update!!")
                return
            }
            view.updateText(to: text)
        }
    }
    
    public func hideTextPromptView(andEraseText: Bool) {
        DispatchQueue.main.async {
            guard let view = self.textPromptView else {
                print("Could not find text prompt view to hide!!!")
                return
            }
            view.hide(andErase: andEraseText)
        }
    }
}

private extension LuminaViewController { //MARK: Button Tap Methods
    @objc func cameraSwitchButtonTapped() {
        self.cameraSwitchButton.isEnabled = false
        switch self.position {
        case .front:
            self.position = .back
            break
        case .back:
            self.position = .front
            break
        case .telephoto:
            self.position = .front
            break
        case .dual:
            self.position = .front
            break
        case .unspecified:
            self.position = .front
            break
        }
    }
    
    @objc func cameraCancelButtonTapped() {
        if let delegate = self.delegate {
            delegate.cancelled(camera: self)
        }
    }
    
    @objc func cameraTorchButtonTapped() {
        // TODO: Update for new camera arch
//        guard let input = self.input else {
//            print("Trying to update torch, but cannot detect device input!")
//            return
//        }
//        if self.torchOn == false {
//            do {
//                if input.device.isTorchModeSupported(.on) {
//                    try input.device.lockForConfiguration()
//                    try input.device.setTorchModeOn(level: 1.0)
//                    self.torchOn = !self.torchOn
//                    input.device.unlockForConfiguration()
//                }
//            } catch {
//                print("Could not turn torch on!!")
//            }
//        } else {
//            do {
//                if input.device.isTorchModeSupported(.off) {
//                    try input.device.lockForConfiguration()
//                    input.device.torchMode = .off
//                    self.torchOn = !self.torchOn
//                    input.device.unlockForConfiguration()
//                }
//            } catch {
//                print("Could not turn torch off!!")
//            }
//        }
    }
}

//private extension CMSampleBuffer { // MARK: Extending CMSampleBuffer
//    var imageFromCoreImage: CGImage? {
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
//            print("Could not get image buffer from CMSampleBuffer")
//            return nil
//        }
//        let coreImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
//        let context: CIContext = CIContext()
//        guard let sample: CGImage = context.createCGImage(coreImage, from: coreImage.extent) else {
//            print("Could not create CoreGraphics image from context")
//            return nil
//        }
//        return sample
//    }
//
//    var imageFromPixelBuffer: CGImage? {
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
//            print("Could not get image buffer from CMSampleBuffer")
//            return nil
//        }
//        if CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0)) == kCVReturnSuccess {
//            var colorSpace = CGColorSpaceCreateDeviceRGB()
//            var bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
//            var width = CVPixelBufferGetWidth(imageBuffer)
//            var height = CVPixelBufferGetHeight(imageBuffer)
//            var bitsPerComponent: size_t = 8
//            var bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
//            var baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
//
//            let format = CVPixelBufferGetPixelFormatType(imageBuffer)
//            if format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
//                baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
//                width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
//                height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
//                bitsPerComponent = 1
//                bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
//                colorSpace = CGColorSpaceCreateDeviceGray()
//                bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
//            }
//
//            let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
//            if let context = context {
//                guard let sample = context.makeImage() else {
//                    print("Could not create CoreGraphics image from context")
//                    return nil
//                }
//                CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
//                return sample
//            } else {
//                print("Could not create CoreGraphics context")
//                return nil
//            }
//        } else {
//            print("Could not lock base address for pixel buffer")
//            return nil
//        }
//    }
//}

//extension LuminaViewController: AVCaptureVideoDataOutputSampleBufferDelegate { // MARK: Image Tracking Output
//    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard case self.trackImages = true else {
//            return
//        }
//        guard let delegate = self.delegate else {
//            print("Warning!! No delegate set, but image tracking turned on")
//            return
//        }
//
////        guard let sampleBuffer = sampleBuffer else {
////            print("No sample buffer detected")
////            return
////        }
//        let startTime = Date()
//        var sample: CGImage? = nil
//        if self.improvedImageDetectionPerformance {
//            sample = sampleBuffer.imageFromPixelBuffer
//        } else {
//            sample = sampleBuffer.imageFromCoreImage
//        }
//        guard let completedSample = sample else {
//            return
//        }
//        let orientation: UIImageOrientation = self.currentCameraDirection == .front ? .left : .right
//        let image = UIImage(cgImage: completedSample, scale: 1.0, orientation: orientation).fixOrientation
//        let end = Date()
//        print("Image tracking processing time: \(end.timeIntervalSince(startTime))")
//        delegate.detected(camera: self, image: image)
//    }
//}

//extension LuminaViewController { // MARK: Tap to focus methods
//    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if self.isUpdating == true {
//            return
//        } else {
//            self.isUpdating = true
//        }
//        for touch in touches {
//            let point = touch.location(in: touch.view)
//            let focusX = point.x/UIScreen.main.bounds.size.width
//            let focusY = point.y/UIScreen.main.bounds.size.height
//            guard let input = self.input else {
//                print("Trying to focus, but cannot detect device input!")
//                return
//            }
//            do {
//                if input.device.isFocusModeSupported(.autoFocus) && input.device.isFocusPointOfInterestSupported {
//                    try input.device.lockForConfiguration()
//                    input.device.focusMode = .autoFocus
//                    input.device.focusPointOfInterest = CGPoint(x: focusX, y: focusY)
//                    if input.device.isExposureModeSupported(.autoExpose) && input.device.isExposurePointOfInterestSupported {
//                        input.device.exposureMode = .autoExpose
//                        input.device.exposurePointOfInterest = CGPoint(x: focusX, y: focusY)
//                    }
//                    input.device.unlockForConfiguration()
//                    showFocusView(at: point)
//                    let deadlineTime = DispatchTime.now() + .seconds(1)
//                    DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
//                        self.resetCameraToContinuousExposureAndFocus()
//                    }
//                } else {
//                    self.isUpdating = false
//                }
//            } catch {
//                print("could not lock for configuration! Not able to focus")
//                self.isUpdating = false
//            }
//        }
//    }
//
//    func resetCameraToContinuousExposureAndFocus() {
//        do {
//            guard let input = self.input else {
//                print("Trying to focus, but cannot detect device input!")
//                return
//            }
//            if input.device.isFocusModeSupported(.continuousAutoFocus) {
//                try input.device.lockForConfiguration()
//                input.device.focusMode = .continuousAutoFocus
//                if input.device.isExposureModeSupported(.continuousAutoExposure) {
//                    input.device.exposureMode = .continuousAutoExposure
//                }
//                input.device.unlockForConfiguration()
//            }
//        } catch {
//            print("could not reset to continuous auto focus and exposure!!")
//        }
//    }
//
//    func showFocusView(at: CGPoint) {
//        let focusView: UIImageView = UIImageView(image: UIImage(named: "cameraFocus", in: Bundle(for: LuminaViewController.self), compatibleWith: nil))
//        focusView.contentMode = .scaleAspectFit
//        focusView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
//        focusView.center = at
//        focusView.alpha = 0.0
//        self.view.addSubview(focusView)
//        UIView.animate(withDuration: 0.2, animations: {
//            focusView.alpha = 1.0
//        }, completion: { complete in
//            UIView.animate(withDuration: 1.0, animations: {
//                focusView.alpha = 0.0
//            }, completion: { final in
//                focusView.removeFromSuperview()
//                self.isUpdating = false
//            })
//        })
//    }
//}

//extension LuminaViewController: AVCaptureMetadataOutputObjectsDelegate { // MARK: Metadata output buffer
//    public func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
//        guard case self.trackMetadata = true else {
//            return
//        }
//        guard let delegate = self.delegate else {
//            return
//        }
//        defer {
//            delegate.detected(camera: self, data: metadataObjects)
//        }
//        if self.drawMetadataBorders == true {
//            guard let previewLayer = self.previewLayer else {
//                return
//            }
//            guard let firstObject = metadataObjects.first else {
//                return
//            }
//            if let _: AVMetadataMachineReadableCodeObject = previewLayer.transformedMetadataObject(for: firstObject ) as? AVMetadataMachineReadableCodeObject { // TODO: Figure out exactly why Faces and Barcodes fire this method separately
//                if let oldBorders = self.metadataBordersCodes {
//                    for oldBorder in oldBorders {
//                        DispatchQueue.main.async {
//                            oldBorder.removeFromSuperview()
//                        }
//                    }
//                }
//                self.metadataBordersCodes = nil
//                var newBorders = [LuminaMetadataBorderView]()
//
//                for metadata in metadataObjects {
//                    guard let transformed: AVMetadataMachineReadableCodeObject = previewLayer.transformedMetadataObject(for: metadata ) as? AVMetadataMachineReadableCodeObject else {
//                        continue
//                    }
//                    var border = LuminaMetadataBorderView()
//                    border.isHidden = true
//                    border.frame = transformed.bounds
//
//                    let translatedCorners = translate(points: transformed.corners, fromView: self.view, toView: border)
//                    border = LuminaMetadataBorderView(frame: transformed.bounds, corners: translatedCorners)
//                    border.isHidden = false
//                    newBorders.append(border)
//                    DispatchQueue.main.async {
//                        self.view.addSubview(border)
//                    }
//                }
//                DispatchQueue.main.async {
//                    self.drawingTimerCodes()
//                }
//                self.metadataBordersCodes = newBorders
//            } else {
//                if let oldBorders = self.metadataBordersFaces {
//                    for oldBorder in oldBorders {
//                        DispatchQueue.main.async {
//                            oldBorder.removeFromSuperview()
//                        }
//                    }
//                }
//                self.metadataBordersFaces = nil
//                var newBorders = [LuminaMetadataBorderView]()
//
//                for metadata in metadataObjects {
//                    guard let face: AVMetadataFaceObject = previewLayer.transformedMetadataObject(for: metadata ) as? AVMetadataFaceObject else {
//                        continue
//                    }
//                    let border = LuminaMetadataBorderView(frame: face.bounds)
//                    border.boundsFace = true
//                    newBorders.append(border)
//                    DispatchQueue.main.async {
//                        self.view.addSubview(border)
//                    }
//                }
//                DispatchQueue.main.async {
//                    self.drawingTimerFaces()
//                }
//                self.metadataBordersFaces = newBorders
//            }
//        }
//    }
//
//    private func translate(points: [CGPoint], fromView: UIView, toView: UIView) -> [CGPoint] {
//        var translatedPoints = [CGPoint]()
//        for point in points {
//            let currentPoint = CGPoint(x: point.x, y: point.y) //CGPoint(x: point["X"] as! Double, y: point["Y"] as! Double)
//            let translatedPoint = fromView.convert(currentPoint, to: toView)
//            translatedPoints.append(translatedPoint)
//        }
//        return translatedPoints
//    }
//
//    private func drawingTimerCodes() {
//        DispatchQueue.main.async {
//            if let _ = self.metadataBordersCodesDestructionTimer {
//                self.metadataBordersCodesDestructionTimer!.invalidate()
//            }
//            self.metadataBordersCodesDestructionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.removeAllBordersCodes), userInfo: nil, repeats: false)
//        }
//    }
//
//    private func drawingTimerFaces() {
//        DispatchQueue.main.async {
//            if let _ = self.metadataBordersFacesDestructionTimer {
//                self.metadataBordersFacesDestructionTimer!.invalidate()
//            }
//            self.metadataBordersFacesDestructionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.removeAllBordersFaces), userInfo: nil, repeats: false)
//        }
//    }
//
//    @objc private func removeAllBordersCodes() {
//        DispatchQueue.main.async {
//            for subview in self.view.subviews {
//                if let border = subview as? LuminaMetadataBorderView, border.boundsFace == false {
//                    border.removeFromSuperview()
//                }
//            }
//            self.metadataBordersCodes = nil
//        }
//    }
//
//    @objc private func removeAllBordersFaces() {
//        DispatchQueue.main.async {
//            for subview in self.view.subviews {
//                if let border = subview as? LuminaMetadataBorderView, border.boundsFace == true {
//                    border.removeFromSuperview()
//                }
//            }
//            self.metadataBordersFaces = nil
//        }
//    }
//}
//
//private extension UIImage { // MARK: Fix UIImage orientation
//    var fixOrientation: UIImage {
//        if imageOrientation == UIImageOrientation.up {
//            return self
//        }
//
//        var transform: CGAffineTransform = CGAffineTransform.identity
//
//        switch imageOrientation {
//        case UIImageOrientation.down, UIImageOrientation.downMirrored:
//            transform = transform.translatedBy(x: size.width, y: size.height)
//            transform = transform.rotated(by: CGFloat.pi)
//            break
//        case UIImageOrientation.left, UIImageOrientation.leftMirrored:
//            transform = transform.translatedBy(x: size.width, y: 0)
//            transform = transform.rotated(by: CGFloat.pi / 2)
//            break
//        case UIImageOrientation.right, UIImageOrientation.rightMirrored:
//            transform = transform.translatedBy(x: 0, y: size.height)
//            transform = transform.rotated(by: CGFloat.pi / -2)
//            break
//        case UIImageOrientation.up, UIImageOrientation.upMirrored:
//            break
//        }
//
//        switch imageOrientation {
//        case UIImageOrientation.upMirrored, UIImageOrientation.downMirrored:
//            transform.translatedBy(x: size.width, y: 0)
//            transform.scaledBy(x: -1, y: 1)
//            break
//        case UIImageOrientation.leftMirrored, UIImageOrientation.rightMirrored:
//            transform.translatedBy(x: size.height, y: 0)
//            transform.scaledBy(x: -1, y: 1)
//        case UIImageOrientation.up, UIImageOrientation.down, UIImageOrientation.left, UIImageOrientation.right:
//            break
//        }
//
//        guard let cgImage = self.cgImage, let colorspace = cgImage.colorSpace else {
//            return self
//        }
//
//        guard let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorspace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
//            return self
//        }
//
//        ctx.concatenate(transform)
//
//        switch imageOrientation {
//        case UIImageOrientation.left, UIImageOrientation.leftMirrored, UIImageOrientation.right, UIImageOrientation.rightMirrored:
//            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
//        default:
//            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
//            break
//        }
//
//        if let convertedCGImage = ctx.makeImage() {
//            return UIImage(cgImage: convertedCGImage)
//        } else {
//            return self
//        }
//    }
//}

