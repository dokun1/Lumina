//
//  ResolutionViewController.swift
//  LuminaSample
//
//  Created by David Okun on 9/27/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import Lumina

protocol ResolutionDelegate: class {
    func didSelect(resolution: CameraResolution, controller: ResolutionViewController)
}

class ResolutionViewController: UITableViewController {
    weak var delegate: ResolutionDelegate?

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CameraResolution.all().count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        guard let textLabel = cell.textLabel else {
            return cell
        }
        textLabel.text = CameraResolution.all()[indexPath.row].rawValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedResolution = CameraResolution.all()[indexPath.row]
        delegate?.didSelect(resolution: selectedResolution, controller: self)
    }
}
