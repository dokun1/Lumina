//
//  ViewController.swift
//  LuminaSample
//
//  Created by David Okun IBM on 4/21/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import Lumina

class ViewController: UITableViewController {
    @IBOutlet weak var frontCameraSwitch: UISwitch!
    @IBOutlet weak var trackImagesSwitch: UISwitch!
    @IBOutlet weak var trackMetadataSwitch: UISwitch!
    @IBOutlet weak var increaseImagePerformanceSwitch: UISwitch!
    @IBOutlet weak var showTextPromptViewSwitch: UISwitch!
    @IBOutlet weak var drawMetadataBorders: UISwitch!
}

extension ViewController { //MARK: IBActions
    @IBAction func cameraButtonTapped() {
        let direction: CameraDirection = frontCameraSwitch.isOn ? .front : .back
        let camera = LuminaController(camera: direction)
        if showTextPromptViewSwitch.isOn {
            camera!.updateTextPromptView(to: "I love Lumina, and I'm going to start using it everywhere!! Blah Blah Blah Blah Blah Blah Blah Blah Blah Blah Blah")
        }
        camera!.delegate = self
        camera!.trackImages = trackImagesSwitch.isOn
        camera!.trackMetadata = trackMetadataSwitch.isOn
        camera!.improvedImageDetectionPerformance = increaseImagePerformanceSwitch.isOn
        camera!.drawMetadataBorders = drawMetadataBorders.isOn
        present(camera!, animated: true, completion: nil)
        let deadline = DispatchTime.now() + .seconds(4)
        DispatchQueue.main.asyncAfter(deadline: deadline) { 
            camera!.updateTextPromptView(to: "And here's what happens after you update the text view on the camera!!!")
            let hideDeadline = DispatchTime.now() + .seconds(2)
            DispatchQueue.main.asyncAfter(deadline: hideDeadline, execute: { 
                camera!.hideTextPromptView(andEraseText: true)
            })
        }
    }
}

extension ViewController: LuminaDelegate {
    func detected(camera: LuminaController, image: UIImage) {
        print("got an image")
    }
    
    func detected(camera: LuminaController, data: [Any]) {
        print("detected data: \(data)")
    }
    
    func cancelled(camera: LuminaController) {
        camera.dismiss(animated: true, completion: nil)
    }
}
