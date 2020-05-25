//
//  LuminaModel.swift
//  Lumina
//
//  Created by David Okun IBM on 5/30/18.
//  Copyright © 2018 David Okun. All rights reserved.
//

import Foundation
import CoreML

/// A class that creates a convenient container for loading Core ML models into Lumina
@available(iOS 11.0, *)
final public class LuminaModel {
    /// The Core ML model file to perform image recognition
    var model: MLModel?
    /// A string that represents the class name of the model performing recognition
    var type: String?

    public init(model: MLModel, type: String) {
        self.model = model
        self.type = type
    }
}
