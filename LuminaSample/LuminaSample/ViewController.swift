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
    @IBOutlet weak var showTextPromptViewSwitch: UISwitch!
}

extension ViewController { //MARK: IBActions
    @IBAction func cameraButtonTapped() {
        let camera = LuminaViewController()
        camera.delegate = self
        camera.position = self.frontCameraSwitch.isOn ? .front : .back
        camera.streamFrames = self.trackImagesSwitch.isOn
        camera.textPrompt = self.showTextPromptViewSwitch.isOn ? "This is how to test the text prompt view" : ""
        camera.trackMetadata = self.trackMetadataSwitch.isOn
        present(camera, animated: true, completion: nil)
    }
}

extension ViewController: LuminaDelegate {
    func detected(controller: LuminaViewController, stillImage: UIImage) {
        controller.dismiss(animated: true) {
            print("image received - check debugger")
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
