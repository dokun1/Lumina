//
//  LoggingViewController.swift
//  LuminaSample
//
//  Created by David Okun on 12/30/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import Lumina

protocol LoggingLevelDelegate: class {
    func didSelect(loggingLevel: LoggerMessageType, controller: LoggingViewController)
}

class LoggingViewController: UITableViewController {
    weak var delegate: LoggingLevelDelegate?
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LoggerMessageType.all().count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        guard let textLabel = cell.textLabel else {
            return cell
        }
        textLabel.text = LoggerMessageType.all()[indexPath.row].description
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLoggingLevel = LoggerMessageType.all()[indexPath.row]
        delegate?.didSelect(loggingLevel: selectedLoggingLevel, controller: self)
    }
}

