import UIKit
import Vision

/// Service responsible for performing OCR on ingredient labels.
class IngredientOCRService {
    static let shared = IngredientOCRService()

    private init() {}

    /// Attempts to recognize text from the provided image and
    /// returns a list of ingredients separated by commas.
    func extractIngredients(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let texts = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
        let joined = texts.joined(separator: " ")

        // Try to isolate ingredient list after the word "ingredients"
        if let range = joined.range(of: "ingredients", options: .caseInsensitive) {
            let after = joined[range.upperBound...]
            return after.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        return joined.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

