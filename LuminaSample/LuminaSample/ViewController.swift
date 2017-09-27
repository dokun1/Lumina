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

class ViewController: UITableViewController {
    @IBOutlet weak var frontCameraSwitch: UISwitch!
    @IBOutlet weak var trackImagesSwitch: UISwitch!
    @IBOutlet weak var trackMetadataSwitch: UISwitch!
    @IBOutlet weak var showTextPromptViewSwitch: UISwitch!
    @IBOutlet weak var frameRateLabel: UILabel!
    @IBOutlet weak var frameRateStepper: UIStepper!
    @IBOutlet weak var useCoreMLModelSwitch: UISwitch!
    @IBOutlet weak var resolutionLabel: UILabel!
    @IBOutlet weak var maxZoomScaleLabel: UILabel!
    @IBOutlet weak var maxZoomScaleStepper: UIStepper!
    
    var selectedResolution: CameraResolution = .high1920x1080
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
        camera.streamFrames = self.trackImagesSwitch.isOn
        camera.textPrompt = self.showTextPromptViewSwitch.isOn ? "This is how to test the text prompt view" : ""
        camera.trackMetadata = self.trackMetadataSwitch.isOn
        camera.resolution = selectedResolution
        camera.maxZoomScale = (self.maxZoomScaleLabel.text! as NSString).floatValue
        camera.frameRate = Int(self.frameRateLabel.text!) ?? 30
        if #available(iOS 11.0, *) {
            camera.streamingModel = self.useCoreMLModelSwitch.isOn ? MobileNet().model : nil
        }
        present(camera, animated: true, completion: nil)
    }
    
    @IBAction func stepperValueChanged() {
        frameRateLabel.text = String(Int(frameRateStepper.value))
    }
    
    @IBAction func zoomStepperChanged() {
        maxZoomScaleLabel.text = String(maxZoomScaleStepper.value)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "stillImageOutputSegue" {
            let controller = segue.destination as! ImageViewController
            controller.image = sender as? UIImage
        } else if segue.identifier == "selectResolutionSegue" {
            let controller = segue.destination as! ResolutionViewController
            controller.delegate = self
        }
    }
}

extension ViewController: LuminaDelegate {
    func detected(controller: LuminaViewController, videoFrame: UIImage, predictions: [LuminaPrediction]?) {
        guard let predicted = predictions else {
            return
        }
        guard let bestPrediction = predicted.first else {
            return
        }
        controller.textPrompt = "Object: \(bestPrediction.name), Confidence: \(bestPrediction.confidence * 100)%"
    }
    
    func detected(controller: LuminaViewController, stillImage: UIImage) {
        controller.dismiss(animated: true) {
            self.performSegue(withIdentifier: "stillImageOutputSegue", sender: stillImage)
        }
    }
    
    func detected(controller: LuminaViewController, videoFrame: UIImage) {
        print("video frame received")
    }
    
    func detected(controller: LuminaViewController, metadata: [Any]) {
        print(metadata)
    }
    
    func cancelled(controller: LuminaViewController) {
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
