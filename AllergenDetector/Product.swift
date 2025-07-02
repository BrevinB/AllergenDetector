//
//  Product.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 5/30/25.
//

import Foundation

struct Product: Codable {
    let barcode: String
    let productName: String
    let allergens: [Allergen]
    let ingredients: [String]
}
