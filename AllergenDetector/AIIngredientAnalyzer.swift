import Foundation

/// Basic AI-powered analyzer that highlights ambiguous ingredients
/// and potential cross-contamination warnings. In a production app
/// this would likely call out to a more sophisticated model or API.
class AIIngredientAnalyzer {
    static let shared = AIIngredientAnalyzer()
    private init() {}

    private let ambiguousTerms = [
        "natural flavor",
        "natural flavours",
        "artificial flavor",
        "spices",
        "seasoning"
    ]

    private let crossContaminationPhrases = [
        "may contain",
        "processed in a facility",
        "manufactured on equipment",
        "may contain traces of"
    ]

    /// Returns any ingredients that are considered ambiguous.
    func findAmbiguous(in ingredients: [String]) -> [String] {
        ingredients.filter { ingredient in
            let lower = ingredient.lowercased()
            return ambiguousTerms.contains { lower.contains($0) }
        }
    }

    /// Returns any detected cross-contamination warnings from the label text.
    func findCrossContamination(in ingredients: [String]) -> [String] {
        let text = ingredients.joined(separator: " ").lowercased()
        return crossContaminationPhrases.filter { text.contains($0) }
    }
}

