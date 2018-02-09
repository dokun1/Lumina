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

public struct LuminaRecognitionResult {
    public var predictions: [LuminaPrediction]?
    
    public var type: Any.Type
}

@available(iOS 11.0, *)
final class LuminaObjectRecognizer: NSObject {
    private var resultProcessingQueue = DispatchQueue(label: "com.lumina.objectRecognizer.resultProcessingQueue")
    private var modelPairs: [(MLModel, Any.Type)]

    init(modelPairs: [(MLModel, Any.Type)]) {
        Log.verbose("initializing object recognizer for \(modelPairs.count) CoreML models")
        self.modelPairs = modelPairs
    }
    
    func recognize(from image: UIImage, completion: @escaping ([LuminaRecognitionResult]?) -> Void) {
        print("creating new recognition")
        guard let coreImage = image.cgImage else {
            completion(nil)
            return
        }
        let recognitionGroup = DispatchGroup()
        var recognitionResults = [LuminaRecognitionResult]()
        var requests = [VNCoreMLRequest]()
        for modelPair in modelPairs {
            print("processing model")
            guard let visionModel = try? VNCoreMLModel(for: modelPair.0) else {
                continue
            }
            recognitionGroup.enter()
            let request = VNCoreMLRequest(model: visionModel) { request, error in
//                self.resultProcessingQueue.sync {
                    print("processing results from \(String(describing: modelPair.1))")
                    if error != nil || request.results == nil {
                        let blankResult = LuminaRecognitionResult(predictions: nil, type: modelPair.1)
                        recognitionResults.append(blankResult)
                    } else if let result = request.results {
                        let mappedResult = LuminaRecognitionResult(predictions: self.mapResults(result), type: modelPair.1)
                        recognitionResults.append(mappedResult)
                    }
                    recognitionGroup.leave()
//                }
            }
            print("appending to request list")
            requests.append(request)
        }
        let handler = VNImageRequestHandler(cgImage: coreImage)
        do {
            try handler.perform(requests)
        } catch {
            Log.error("Could not perform requests with CoreML")
            completion(nil)
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
