//
//  LuminaObjectRecognition.swift
//  Lumina
//
//  Created by David Okun on 9/25/17.
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
    private var modelPairs: [(MLModel, Any.Type)]

    init(modelPairs: [(MLModel, Any.Type)]) {
        Log.verbose("initializing object recognizer for \(modelPairs.count) CoreML models")
        self.modelPairs = modelPairs
    }

    func recognize(from image: UIImage, completion: @escaping ([([LuminaPrediction]?, Any.Type)]) -> Void) {
        var recognitionResults = [([LuminaPrediction]?, Any.Type)]()
        let recognitionGroup = DispatchGroup()
        for modelPair in modelPairs {
            recognitionGroup.enter()
            guard let visionModel = try? VNCoreMLModel(for: modelPair.0) else {
                recognitionGroup.leave()
                continue
            }
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if error != nil || request.results == nil {
                    recognitionResults.append((nil, modelPair.1))
                    recognitionGroup.leave()
                } else if let results = request.results {
                    let mappedResults = self.mapResults(results)
                    recognitionResults.append((mappedResults, modelPair.1))
                    recognitionGroup.leave()
                }
            }
            guard let coreImage = image.cgImage else {
                recognitionGroup.leave()
                continue
            }
            let handler = VNImageRequestHandler(cgImage: coreImage)
            do {
                try handler.perform([request])
            } catch {
                recognitionGroup.leave()
            }
        }
        recognitionGroup.notify(queue: DispatchQueue.main) {
            Log.verbose("object recognizer finished scanning image - returning results from models")
            completion(recognitionResults)
        }
    }

    private func mapResults(_ objects: [Any]) -> [LuminaPrediction] {
        var results = [LuminaPrediction]()
        for object in objects {
            if let object = object as? VNClassificationObservation {
                results.append(LuminaPrediction(name: object.identifier, confidence: object.confidence))
            }
        }
        return results.sorted(by: {
            $0.confidence > $1.confidence
        })
    }
}
