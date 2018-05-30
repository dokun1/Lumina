//
//  LuminaModel.swift
//  Lumina
//
//  Created by David Okun IBM on 5/30/18.
//  Copyright © 2018 David Okun. All rights reserved.
//

import Foundation
import CoreML

@available(iOS 11.0, *)
final public class LuminaModel {
    var model: MLModel?
    var type: String?

    public init(model: MLModel, type: String) {
        self.model = model
        self.type = type
    }
}
