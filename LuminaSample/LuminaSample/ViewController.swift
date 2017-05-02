//
//  ViewController.swift
//  LuminaSample
//
//  Created by David Okun IBM on 4/21/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import Lumina

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let camera = LuminaController(camera: .back) else {
            return
        }
        camera.delegate = self
        present(camera, animated: true, completion: nil)
    }
}

extension ViewController: LuminaDelegate {
    func detected(image: UIImage) {
        print("got an image")
    }
    
    func detected(data: Data) {
        
    }
}
