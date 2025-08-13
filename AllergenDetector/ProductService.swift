//
//  ProductService.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 5/30/25.
//

import Foundation

class ProductService {
    static let shared = ProductService()
    
    // Directory for caching product JSON data
    private let cacheDirectory: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let base = urls[0].appendingPathComponent("ProductCache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }()

    func fetchProduct(barcode: String) async throws -> Product {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        do {
            // Attempt network fetch
            let (data, _) = try await URLSession.shared.data(from: url)
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            let product = try apiResponse.toProduct()
            
            // Cache raw JSON for offline use
            cacheProductData(data, for: barcode)
            
            return product
        } catch {
            // On network error, attempt to load from cache
            if let _ = error as? URLError,
               let cachedData = loadCachedData(for: barcode) {
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: cachedData)
                let product = try apiResponse.toProduct()
                return product
            }
            // If no cache or a different error, rethrow
            throw error
        }
    }
    
    // Save raw JSON data to cache
    private func cacheProductData(_ data: Data, for barcode: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(barcode).json")
        try? data.write(to: fileURL)
    }
    
    // Load cached JSON data if it exists
    private func loadCachedData(for barcode: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent("\(barcode).json")
        return try? Data(contentsOf: fileURL)
    }
}

enum ProductError: Error {
    case productNotFound
}

private struct APIResponse: Codable {
    let code: String
    let status: Int?
    let status_verbose: String?
    let product: APIProduct?
   
    
    func toProduct() throws -> Product {
        // If status != 1 OR product is nil → not found
        guard let status = status, status == 1, let apiProd = product else {
            throw ProductError.productNotFound
        }
        let allergens: [Allergen] = apiProd.allergens_tags?
            .compactMap { tag in Allergen(rawValue: tag.replacingOccurrences(of: "en:", with: "")) }
            ?? []
        let ingredients = apiProd.ingredients_tags ?? []
        return Product(
            barcode: code,
            productName: apiProd.product_name ?? "Unknown",
            allergens: allergens,
            ingredients: ingredients
        )
    }
}

private struct APIProduct: Codable {
    let product_name: String?
    let allergens_tags: [String]?
    let ingredients_tags: [String]?
}
