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
}

extension ViewController { //MARK: IBActions
    @IBAction func cameraButtonTapped() {
        let direction: CameraDirection = frontCameraSwitch.isOn ? .front : .back
        guard let camera = LuminaController(camera: direction) else {
            return
        }
        camera.delegate = self
        camera.trackImages = trackImagesSwitch.isOn
        present(camera, animated: true, completion: nil)
    }
}

extension ViewController: LuminaDelegate {
    func detected(camera: LuminaController, image: UIImage) {
        print("got an image")
    }
    
    func detected(camera: LuminaController, data: [Any]) {
        print("detected data")
    }
    
    func cancelled(camera: LuminaController) {
        camera.dismiss(animated: true, completion: nil)
    }
    
}
