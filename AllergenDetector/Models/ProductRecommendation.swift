//
//  ProductRecommendation.swift
//  AllergenDetector
//
//  Models for product recommendations
//

import Foundation

/// A recommended alternative product
struct ProductRecommendation: Identifiable {
    let id = UUID()
    let barcode: String
    let productName: String
    let brand: String?
    let category: String?
    let isSafe: Bool
    let matchScore: Double  // 0.0 to 1.0 - how similar to original

    /// Creates a recommendation from Open Food Facts search result
    init(barcode: String, productName: String, brand: String? = nil, category: String? = nil, isSafe: Bool = true, matchScore: Double = 0.5) {
        self.barcode = barcode
        self.productName = productName
        self.brand = brand
        self.category = category
        self.isSafe = isSafe
        self.matchScore = matchScore
    }
}

/// Category suggestions for common allergen-containing products
enum ProductCategory: String, CaseIterable {
    case dairy = "Dairy Products"
    case bread = "Bread & Bakery"
    case snacks = "Snacks"
    case beverages = "Beverages"
    case cereals = "Cereals"
    case desserts = "Desserts"
    case condiments = "Condiments & Sauces"
    case meat = "Meat & Seafood"
    case produce = "Fruits & Vegetables"
    case other = "Other"

    /// Keywords to help categorize products
    var keywords: [String] {
        switch self {
        case .dairy:
            return ["milk", "cheese", "yogurt", "butter", "cream", "dairy"]
        case .bread:
            return ["bread", "bagel", "roll", "bun", "muffin", "croissant"]
        case .snacks:
            return ["chip", "cracker", "cookie", "snack", "popcorn", "pretzel"]
        case .beverages:
            return ["drink", "juice", "soda", "water", "tea", "coffee", "beverage"]
        case .cereals:
            return ["cereal", "granola", "oat", "wheat", "corn flakes"]
        case .desserts:
            return ["ice cream", "cake", "pie", "dessert", "candy", "chocolate"]
        case .condiments:
            return ["sauce", "dressing", "mayo", "ketchup", "mustard", "condiment"]
        case .meat:
            return ["meat", "fish", "chicken", "beef", "pork", "seafood"]
        case .produce:
            return ["fruit", "vegetable", "apple", "banana", "carrot"]
        case .other:
            return []
        }
    }

    /// Attempts to categorize a product based on its name
    static func categorize(_ productName: String) -> ProductCategory {
        let lowercased = productName.lowercased()

        for category in ProductCategory.allCases where category != .other {
            if category.keywords.contains(where: { lowercased.contains($0) }) {
                return category
            }
        }

        return .other
    }
}
