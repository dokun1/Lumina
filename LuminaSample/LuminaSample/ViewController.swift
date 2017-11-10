//
//  ViewController.swift
//  LuminaSample
//
//  Created by David Okun on 4/21/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import Lumina
import CoreML
import AVKit

class ViewController: UITableViewController {
    @IBOutlet weak var frontCameraSwitch: UISwitch!
    @IBOutlet weak var recordsVideoSwitch: UISwitch!
    @IBOutlet weak var trackImagesSwitch: UISwitch!
    @IBOutlet weak var trackMetadataSwitch: UISwitch!
    @IBOutlet weak var capturesLivePhotosSwitch: UISwitch!
    @IBOutlet weak var capturesDepthDataSwitch: UISwitch!
    @IBOutlet weak var streamsDepthDataSwitch: UISwitch!
    @IBOutlet weak var showTextPromptViewSwitch: UISwitch!
    @IBOutlet weak var frameRateLabel: UILabel!
    @IBOutlet weak var frameRateSlider: UISlider!
    @IBOutlet weak var useCoreMLModelSwitch: UISwitch!
    @IBOutlet weak var resolutionLabel: UILabel!
    @IBOutlet weak var maxZoomScaleLabel: UILabel!
    @IBOutlet weak var maxZoomScaleSlider: UISlider!
    
    var selectedResolution: CameraResolution = .photo
}

extension ViewController { //MARK: IBActions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.resolutionLabel.text = selectedResolution.rawValue
        if let version = LuminaViewController.getVersion() {
            self.title = "Lumina Sample v\(version)"
        }
    }
    
    @IBAction func cameraButtonTapped() {
        let camera = LuminaViewController()
        camera.delegate = self
        camera.position = self.frontCameraSwitch.isOn ? .front : .back
        camera.recordsVideo = self.recordsVideoSwitch.isOn
        camera.streamFrames = self.trackImagesSwitch.isOn
        camera.textPrompt = self.showTextPromptViewSwitch.isOn ? "This is how to test the text prompt view" : ""
        camera.trackMetadata = self.trackMetadataSwitch.isOn
        camera.captureLivePhotos = self.capturesLivePhotosSwitch.isOn
        camera.captureDepthData = self.capturesDepthDataSwitch.isOn
        camera.streamDepthData = self.streamsDepthDataSwitch.isOn
        camera.resolution = selectedResolution
        camera.maxZoomScale = (self.maxZoomScaleLabel.text! as NSString).floatValue
        camera.frameRate = Int(self.frameRateLabel.text!) ?? 30
        if #available(iOS 11.0, *) {
            camera.streamingModel = self.useCoreMLModelSwitch.isOn ? MobileNet().model : nil
        }
        present(camera, animated: true, completion: nil)
    }
    
    @IBAction func frameRateSliderChanged() {
        frameRateLabel.text = String(Int(frameRateSlider.value))
    }
    
    @IBAction func zoomScaleSliderChanged() {
        maxZoomScaleLabel.text = String(format: "%.01f", maxZoomScaleSlider.value)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "stillImageOutputSegue" {
            let controller = segue.destination as! ImageViewController
            if let map = sender as? [String : Any] {
                controller.image = map["stillImage"] as? UIImage
                controller.livePhotoURL = map["livePhotoURL"] as? URL
                if #available(iOS 11.0, *) {
                    controller.depthData = map["depthData"] as? AVDepthData
                }
            } else { return }
        } else if segue.identifier == "selectResolutionSegue" {
            let controller = segue.destination as! ResolutionViewController
            controller.delegate = self
        }
    }
}

extension ViewController: LuminaDelegate {
    func captured(stillImage: UIImage, livePhotoAt: URL?, depthData: Any?, from controller: LuminaViewController) {
        controller.dismiss(animated: true) {
            self.performSegue(withIdentifier: "stillImageOutputSegue", sender: ["stillImage" : stillImage, "livePhotoURL" : livePhotoAt as Any, "depthData" : depthData])
        }
    }
    
    func captured(videoAt: URL, from controller: LuminaViewController) {
        controller.dismiss(animated: true) {
            let player = AVPlayer(url: videoAt)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        }
    }
    
    func streamed(videoFrame: UIImage, with predictions: [LuminaPrediction]?, from controller: LuminaViewController) {
        guard let predicted = predictions else {
            return
        }
        guard let bestPrediction = predicted.first else {
            return
        }
        controller.textPrompt = "Object: \(bestPrediction.name), Confidence: \(bestPrediction.confidence * 100)%"
    }
    
    func detected(metadata: [Any], from controller: LuminaViewController) {
        print(metadata)
    }
    
    func streamed(videoFrame: UIImage, from controller: LuminaViewController) {
        print("video frame received")
    }
    
    func streamed(depthData: Any, from controller: LuminaViewController) {
        if #available(iOS 11.0, *) {
            if let _ = depthData as? AVDepthData {
                print("got depth data")
            }
        }
    }
    
    func dismissed(controller: LuminaViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: ResolutionDelegate {
    func didSelect(resolution: CameraResolution, controller: ResolutionViewController) {
        selectedResolution = resolution
        if let navigationController = self.navigationController {
            navigationController.popToViewController(self, animated: true)
        }
    }
}
