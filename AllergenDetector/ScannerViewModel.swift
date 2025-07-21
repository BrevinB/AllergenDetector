//
//  ScannerViewModel.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 5/30/25.
//

import Foundation
import SwiftUI

@MainActor
class ScannerViewModel: ObservableObject {
    struct AllergenMatchDetail {
        let ingredient: String
        let allergenName: String
        let explanation: String
    }

    static let ingredientToAllergen: [String: (allergen: Allergen, explanation: String)] = [
        "casein": (.dairy, "Casein is a milk protein and a common allergen for those sensitive to dairy."),
        "whey": (.dairy, "Whey is derived from milk and a source of dairy allergens."),
        "albumin": (.eggs, "Albumin is a protein found in egg whites."),
        "egg": (.eggs, "Eggs are a common allergen."),
        "globulin": (.eggs, "Globulin is an egg white protein."),
        "ovalbumin": (.eggs, "Ovalbumin is a major egg white protein."),
        "ovomucoid": (.eggs, "Ovomucoid is a protein found in egg whites."),
        "lysozyme": (.eggs, "Lysozyme is an enzyme from egg whites."),
        "ovovitellin": (.eggs, "Ovovitellin is a protein in egg yolk."),
        "e1105": (.eggs, "E1105 (lysozyme) is an enzyme from egg whites."),
        "soy": (.soy, "Soy is a common allergen."),
        "soya": (.soy, "Soya is an alternate name for soy."),
        "soybean": (.soy, "Soybean is a source of soy allergen."),
        "edamame": (.soy, "Edamame is young soybean."),
        "tofu": (.soy, "Tofu is made from soybeans."),
        "textured vegetable protein": (.soy, "Textured vegetable protein (TVP) is usually made from soy."),
        "tvp": (.soy, "TVP is usually made from soy."),
        "lecithin": (.soy, "Lecithin (often E322) is usually from soy but can come from eggs."),
        "e322": (.soy, "E322 (lecithin) is typically derived from soy, but can also come from eggs."),
        "fish": (.fish, "Fish is a common allergen."),
        "anchovy": (.fish, "Anchovy is a type of fish."),
        "cod": (.fish, "Cod is a type of fish."),
        "salmon": (.fish, "Salmon is a type of fish."),
        "tuna": (.fish, "Tuna is a type of fish."),
        "fish oil": (.fish, "Fish oil is derived from fish."),
        "fish gelatin": (.fish, "Fish gelatin comes from fish bones/skin."),
        "shrimp": (.shellfish, "Shrimp is a type of shellfish."),
        "prawn": (.shellfish, "Prawn is a type of shellfish."),
        "crab": (.shellfish, "Crab is a type of shellfish."),
        "lobster": (.shellfish, "Lobster is a type of shellfish."),
        "scallop": (.shellfish, "Scallop is a type of mollusk/shellfish."),
        "clam": (.shellfish, "Clam is a type of shellfish."),
        "oyster": (.shellfish, "Oyster is a type of shellfish."),
        "mussel": (.shellfish, "Mussel is a type of shellfish."),
        "peanut": (.peanuts, "Peanuts are a common allergen."),
        "groundnut": (.peanuts, "Groundnut is another name for peanut."),
        "monkey nut": (.peanuts, "Monkey nut is another name for peanut."),
        "arachis oil": (.peanuts, "Arachis oil is peanut oil."),
        "almond": (.treeNuts, "Almond is a tree nut."),
        "brazil nut": (.treeNuts, "Brazil nut is a tree nut."),
        "cashew": (.treeNuts, "Cashew is a tree nut."),
        "chestnut": (.treeNuts, "Chestnut is a tree nut."),
        "hazelnut": (.treeNuts, "Hazelnut is a tree nut."),
        "macadamia": (.treeNuts, "Macadamia nut is a tree nut."),
        "pecan": (.treeNuts, "Pecan is a tree nut."),
        "pistachio": (.treeNuts, "Pistachio is a tree nut."),
        "walnut": (.treeNuts, "Walnut is a tree nut."),
        "nut oil": (.treeNuts, "Nut oil is often derived from tree nuts."),
        "sesame": (.sesame, "Sesame is a common allergen."),
        "tahini": (.sesame, "Tahini is made from sesame seeds."),
        "benne": (.sesame, "Benne is another name for sesame."),
        "gingelly": (.sesame, "Gingelly is another name for sesame."),
        "mustard": (.mustard, "Mustard is a common allergen."),
        "mustard flour": (.mustard, "Mustard flour is ground mustard seed."),
        "mustard oil": (.mustard, "Mustard oil comes from mustard seeds."),
        "mustard seed": (.mustard, "Mustard seed is a source of mustard allergen."),
        "celery": (.celery, "Celery is a common allergen."),
        "celeriac": (.celery, "Celeriac is a type of celery root."),
        "lupin": (.lupin, "Lupin is a legume sometimes used in flour."),
        "lupine": (.lupin, "Lupine is another spelling for lupin."),
        "sulfite": (.sulfites, "Sulfites are preservatives that can trigger allergies."),
        "sulphite": (.sulfites, "Sulphite is a British spelling of sulfite."),
        "sulfur dioxide": (.sulfites, "Sulfur dioxide is a sulfite compound."),
        "e220": (.sulfites, "E220 (Sulfur dioxide) is a sulfite."),
        "e221": (.sulfites, "E221 (Sodium sulfite) is a sulfite."),
        "e222": (.sulfites, "E222 (Sodium bisulfite) is a sulfite."),
        "e223": (.sulfites, "E223 (Sodium metabisulfite) is a sulfite."),
        "e224": (.sulfites, "E224 (Potassium metabisulfite) is a sulfite."),
        "e225": (.sulfites, "E225 (Potassium sulfite) is a sulfite."),
        "e226": (.sulfites, "E226 (Calcium sulfite) is a sulfite."),
        "e227": (.sulfites, "E227 (Calcium hydrogen sulfite) is a sulfite."),
        "e228": (.sulfites, "E228 (Potassium hydrogen sulfite) is a sulfite."),
        "gluten": (.gluten, "Gluten is found in wheat, barley, and rye."),
        "nuts": (.nuts, "Nuts are a common allergen group, including peanuts and tree nuts."),
        "red 40": (.foodDyes, "Red 40 is a synthetic food dye (Allura Red)."),
        "yellow 5": (.foodDyes, "Yellow 5 is a synthetic food dye (Tartrazine)."),
        "yellow 6": (.foodDyes, "Yellow 6 is a synthetic food dye (Sunset Yellow)."),
        "blue 1": (.foodDyes, "Blue 1 is a synthetic food dye (Brilliant Blue)."),
        "blue 2": (.foodDyes, "Blue 2 is a synthetic food dye (Indigo Carmine)."),
        "green 3": (.foodDyes, "Green 3 is a synthetic food dye (Fast Green)."),
        "orange b": (.foodDyes, "Orange B is a food dye."),
        "citrus red 2": (.foodDyes, "Citrus Red 2 is a synthetic food dye."),
        "food coloring": (.foodDyes, "General food coloring ingredient."),
        "e129": (.foodDyes, "Red 40 (Allura Red, E129) is a synthetic food dye."),
        "e133": (.foodDyes, "Blue 1 (Brilliant Blue, E133) is a synthetic food dye."),
        "e102": (.foodDyes, "Yellow 5 (Tartrazine, E102) is a synthetic food dye."),
        "e110": (.foodDyes, "Yellow 6 (Sunset Yellow, E110) is a synthetic food dye."),
        "e122": (.foodDyes, "Carmoisine (E122) is a synthetic food dye."),
        "e124": (.foodDyes, "Ponceau 4R (E124) is a synthetic food dye."),
        "e104": (.foodDyes, "Quinoline Yellow (E104) is a synthetic food dye."),
        "e132": (.foodDyes, "Indigo Carmine (Blue 2, E132) is a synthetic food dye.")
        // Add more as needed
    ]
    
    @Published var scannedProduct: Product?
    @Published var isLoading = false
    @Published var alertMessage: String?
    @Published var showAlert = false
    @Published var matchDetails: [AllergenMatchDetail] = []
    @Published var allergenStatuses: [Allergen: Bool] = [:]

    func handleBarcode(
        _ code: String,
        selectedAllergens: Set<Allergen>,
        customAllergens: [String]
    ) {
        isLoading = true
        Task {
            do {
                let product = try await ProductService.shared.fetchProduct(barcode: code)
                scannedProduct = product
                checkAllergens(
                    product,
                    selectedAllergens: selectedAllergens,
                    customAllergens: customAllergens
                )
            } catch _ as ProductError {
                alertMessage = "Product not found in database. Please try another barcode."
                showAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            } catch _ as URLError {
                alertMessage = "No internet connection and no cached data available."
                showAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            } catch {
                alertMessage = "An error occurred while searching for the product. Please check your connection."
                showAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            isLoading = false
        }
    }

    private func checkAllergens(
        _ product: Product,
        selectedAllergens: Set<Allergen>,
        customAllergens: [String]
    ) {
        print("[DEBUG] Ingredients for \(product.productName):", product.ingredients)
        
        let intersection = Set(product.allergens).intersection(selectedAllergens)

        var detailsArray: [AllergenMatchDetail] = []
        
        for ingredient in product.ingredients {
            let lowerIngredient = ingredient.lowercased()
            
            // Old strict matching logic (commented out):
            /*
            let key = ingredient.lowercased()
            if let mapped = Self.ingredientToAllergen[key], selectedAllergens.contains(mapped.allergen) {
                let detail = AllergenMatchDetail(ingredient: ingredient, allergen: mapped.allergen, explanation: mapped.explanation)
                detailsArray.append(detail)
            }
            */
            
            for (key, mapped) in Self.ingredientToAllergen {
                if lowerIngredient.contains(key) && selectedAllergens.contains(mapped.allergen) {
                    if !detailsArray.contains(where: { $0.ingredient == ingredient && $0.allergenName == mapped.allergen.displayName }) {
                        let detail = AllergenMatchDetail(
                            ingredient: ingredient,
                            allergenName: mapped.allergen.displayName,
                            explanation: mapped.explanation
                        )
                        detailsArray.append(detail)
                    }
                }
            }

            for custom in customAllergens {
                let customLower = custom.lowercased()
                if lowerIngredient.contains(customLower) {
                    if !detailsArray.contains(where: { $0.ingredient == ingredient && $0.allergenName.lowercased() == customLower }) {
                        let detail = AllergenMatchDetail(
                            ingredient: ingredient,
                            allergenName: custom,
                            explanation: "Custom allergen match"
                        )
                        detailsArray.append(detail)
                    }
                }
            }
        }
        
        // Determine which allergens were flagged either from the product's
        // reported allergens or via ingredient matching
        let ingredientAllergens = Set(detailsArray.map { $0.allergen })
        let flaggedAllergens = intersection.union(ingredientAllergens)

        // Build status dictionary for each selected allergen
        var statusDict: [Allergen: Bool] = [:]
        for allergen in selectedAllergens {
            statusDict[allergen] = !flaggedAllergens.contains(allergen)
        }

        let isSafe = !statusDict.values.contains(false)

        self.matchDetails = detailsArray
        self.allergenStatuses = statusDict

        // Compose alert message summarizing safety
        if isSafe {
            alertMessage = "\(product.productName) is safe to eat!"
        } else {

            let baseNames = intersection.map { $0.displayName }
            let detailNames = detailsArray.map { $0.allergenName }
            let names = Array(Set(baseNames + detailNames)).joined(separator: ", ")
            alertMessage = "Warning: contains \(names)."
        }

        let statusLines = selectedAllergens
            .sorted { $0.displayName < $1.displayName }
            .map { allergen in
                let safe = statusDict[allergen] ?? true
                return "\(allergen.displayName): " + (safe ? "Safe" : "Not Safe")
            }
            .joined(separator: "\n")
        alertMessage! += "\n" + statusLines

        if !detailsArray.isEmpty {
            alertMessage! += "\nDetails:"
            for detail in detailsArray {
                alertMessage! += "\n\(detail.ingredient): \(detail.allergenName) - \(detail.explanation)"
            }
        }
        
        let generator = UINotificationFeedbackGenerator()
        if isSafe {
            generator.notificationOccurred(.success)
        } else {
            generator.notificationOccurred(.warning)
        }
        showAlert = true
        
        let record = ScanRecord(
            id: UUID(),
            barcode: product.barcode,
            productName: product.productName,
            dateScanned: Date(),
            isSafe: isSafe
        )
        HistoryService.shared.addRecord(record)
    }
}

