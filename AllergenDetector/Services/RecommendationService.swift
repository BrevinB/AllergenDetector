//
//  RecommendationService.swift
//  AllergenDetector
//
//  Service to find safe alternative products
//

import Foundation

/// Service for finding product recommendations
class RecommendationService {
    static let shared = RecommendationService()

    private init() {}

    /// Finds safe alternative products for a given product
    func findAlternatives(
        for product: Product,
        avoidingAllergens allergens: Set<Allergen>,
        customAllergens: [String]
    ) async -> [ProductRecommendation] {
        // Determine category from product name
        let category = ProductCategory.categorize(product.productName)

        // Build search query
        let searchTerms = buildSearchTerms(from: product.productName, category: category)

        // Search for similar products
        let searchResults = await searchProducts(query: searchTerms, limit: 20)

        // Filter and score results
        var recommendations: [ProductRecommendation] = []

        for result in searchResults {
            // Skip the original product
            if result.barcode == product.barcode {
                continue
            }

            // Check if this product is safe
            let isSafe = checkSafety(
                ingredients: result.ingredients,
                allergens: allergens,
                customAllergens: customAllergens
            )

            // Only recommend safe products
            if isSafe {
                let score = calculateMatchScore(
                    original: product.productName,
                    candidate: result.productName
                )

                let recommendation = ProductRecommendation(
                    barcode: result.barcode,
                    productName: result.productName,
                    brand: nil,
                    category: category.rawValue,
                    isSafe: true,
                    matchScore: score
                )

                recommendations.append(recommendation)
            }
        }

        // Sort by match score (highest first) and limit to top 10
        return recommendations
            .sorted { $0.matchScore > $1.matchScore }
            .prefix(10)
            .map { $0 }
    }

    // MARK: - Private Helper Methods

    /// Builds search terms from product name and category
    private func buildSearchTerms(from productName: String, category: ProductCategory) -> String {
        // Extract key terms from product name
        var terms: [String] = []

        // Add category as primary search term
        if category != .other {
            terms.append(category.rawValue.lowercased())
        }

        // Extract brand/key words from product name
        let words = productName
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }
            .prefix(3)

        terms.append(contentsOf: words)

        return terms.joined(separator: " ")
    }

    /// Searches Open Food Facts for products matching query
    private func searchProducts(query: String, limit: Int) async -> [Product] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&json=1&page_size=\(limit)"

        guard let url = URL(string: urlString) else {
            return []
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)

            return searchResponse.products.compactMap { apiProduct in
                guard let productName = apiProduct.product_name,
                      let code = apiProduct.code,
                      !productName.isEmpty else {
                    return nil
                }

                let ingredients = apiProduct.ingredients_tags ?? []

                return Product(
                    barcode: code,
                    productName: productName,
                    allergens: [],  // Not using allergen tags for recommendations
                    ingredients: ingredients
                )
            }
        } catch {
            print("Search error: \(error)")
            return []
        }
    }

    /// Checks if a product is safe based on ingredients
    private func checkSafety(
        ingredients: [String],
        allergens: Set<Allergen>,
        customAllergens: [String]
    ) -> Bool {
        // Check against built-in allergens
        for ingredient in ingredients {
            let lowerIngredient = ingredient.lowercased()

            // Check allergen mapping (from ScannerViewModel)
            for (key, mapped) in ScannerViewModel.ingredientToAllergen {
                if lowerIngredient.contains(key) && allergens.contains(mapped.allergen) {
                    return false
                }
            }

            // Check custom allergens
            for custom in customAllergens {
                if lowerIngredient.contains(custom.lowercased()) {
                    return false
                }
            }
        }

        return true
    }

    /// Calculates similarity score between two product names
    private func calculateMatchScore(original: String, candidate: String) -> Double {
        let originalWords = Set(original.lowercased().components(separatedBy: .whitespaces))
        let candidateWords = Set(candidate.lowercased().components(separatedBy: .whitespaces))

        let intersection = originalWords.intersection(candidateWords)
        let union = originalWords.union(candidateWords)

        guard !union.isEmpty else { return 0.0 }

        // Jaccard similarity
        return Double(intersection.count) / Double(union.count)
    }
}

// MARK: - Search API Response Models

private struct SearchResponse: Codable {
    let count: Int?
    let page: Int?
    let page_size: Int?
    let products: [SearchProduct]
}

private struct SearchProduct: Codable {
    let code: String?
    let product_name: String?
    let brands: String?
    let categories: String?
    let ingredients_tags: [String]?
}
