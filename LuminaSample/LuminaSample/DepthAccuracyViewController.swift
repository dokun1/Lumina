//
//  DepthAccuracyViewController.swift
//  LuminaSample
//
//  Created by David Okun IBM on 9/4/18.
//  Copyright © 2018 David Okun. All rights reserved.
//

import UIKit
import Lumina

@available(iOS 11.0, *)
protocol DepthAccuracyDelegate: class {
    func didSelect(accuracy: LuminaDepthAccuracy, controller: DepthAccuracyViewController)
}

@available(iOS 11.0, *)
class DepthAccuracyViewController: UITableViewController {
    weak var delegate: DepthAccuracyDelegate?
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        guard let textLabel = cell.textLabel else {
            return cell
        }
        if indexPath.row == 0 {
            textLabel.text = "Absolute"
        } else {
            textLabel.text = "Relative"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelect(accuracy: indexPath.row == 0 ? .absolute : .relative, controller: self)
    }
}
