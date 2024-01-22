//
//  ImageClassifier.swift
//  ImageRecognition
//
//  Created by Ömer Köse on 14.01.2024.
//

import UIKit
import Foundation
import CoreML
import Vision

class ImageClassifierWrapper {
    private var model: VNCoreMLModel
    init() {
        guard let mlModel = try? MobileNetV2(configuration: .init()).model,
              let vnModel = try? VNCoreMLModel(for: mlModel) else {
            fatalError("Error: Unable to initialize MobileNetV2 model.")
        }
        self.model = vnModel
    }
    func ClassifyImage(image: CIImage) -> String {
        var result: VNClassificationObservation?
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Error: Unable to retrive results.")
            }
            result = results.first
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        if let description = result?.identifier.description {
            return description.capitalized
        }
        return ""
    }
}
