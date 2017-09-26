//
//  LuminaObjectRecognition.swift
//  Lumina
//
//  Created by David Okun IBM on 9/25/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit
import CoreML
import Vision

/// An object that represents a prediction about an object that Lumina detects
public struct LuminaPrediction {
    /// The name of the object, as predicted by Lumina
    public var name: String
    /// The numeric value of the confidence of the prediction, out of 1.0
    public var confidence: Float
}

@available(iOS 11.0, *)
final class LuminaObjectRecognizer: NSObject {
    private var model: MLModel
    
    init(model: MLModel) {
        self.model = model
    }
    
    func recognize(from image: UIImage, completion: @escaping (_ predictions: [LuminaPrediction]?) -> Void) {
        guard let visionModel = try? VNCoreMLModel(for: self.model) else {
            completion(nil)
            return
        }
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if error != nil || request.results == nil{
                completion(nil)
            } else if let results = request.results {
                completion(self.mapResults(results))
            }
        }
        guard let coreImage = image.cgImage else {
            completion(nil)
            return
        }
        let handler = VNImageRequestHandler(cgImage: coreImage)
        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }
    
    private func mapResults(_ objects: [Any]) -> [LuminaPrediction] {
        var results = [LuminaPrediction]()
        for object in objects as! [VNClassificationObservation] {
            results.append(LuminaPrediction(name: object.identifier, confidence: object.confidence))
        }
        return results.sorted(by: {
            $0.confidence > $1.confidence
        })
    }
}
