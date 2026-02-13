//
//  AllergenDetectorTests.swift
//  AllergenDetectorTests
//
//  Unit tests for AllergenDetector core logic
//

import XCTest
@testable import AllergenDetector

// MARK: - Allergen Model Tests

final class AllergenTests: XCTestCase {
    func testAllCasesCount() {
        XCTAssertEqual(Allergen.allCases.count, 15)
    }

    func testDisplayNames() {
        XCTAssertEqual(Allergen.gluten.displayName, "Gluten")
        XCTAssertEqual(Allergen.dairy.displayName, "Dairy")
        XCTAssertEqual(Allergen.treeNuts.displayName, "Tree Nuts")
        XCTAssertEqual(Allergen.foodDyes.displayName, "Food Dyes")
    }

    func testIdentifiable() {
        XCTAssertEqual(Allergen.gluten.id, "gluten")
        XCTAssertEqual(Allergen.treeNuts.id, "treeNuts")
    }

    func testCodable() throws {
        let allergen = Allergen.dairy
        let data = try JSONEncoder().encode(allergen)
        let decoded = try JSONDecoder().decode(Allergen.self, from: data)
        XCTAssertEqual(allergen, decoded)
    }
}

// MARK: - Product Model Tests

final class ProductTests: XCTestCase {
    func testProductCreation() {
        let product = Product(
            barcode: "1234567890",
            productName: "Test Product",
            allergens: [.dairy, .gluten],
            ingredients: ["milk", "wheat flour"]
        )

        XCTAssertEqual(product.barcode, "1234567890")
        XCTAssertEqual(product.productName, "Test Product")
        XCTAssertEqual(product.allergens.count, 2)
        XCTAssertEqual(product.ingredients.count, 2)
    }

    func testProductCodable() throws {
        let product = Product(
            barcode: "1234567890",
            productName: "Test Product",
            allergens: [.dairy],
            ingredients: ["milk"]
        )

        let data = try JSONEncoder().encode(product)
        let decoded = try JSONDecoder().decode(Product.self, from: data)

        XCTAssertEqual(decoded.barcode, product.barcode)
        XCTAssertEqual(decoded.productName, product.productName)
        XCTAssertEqual(decoded.allergens, product.allergens)
        XCTAssertEqual(decoded.ingredients, product.ingredients)
    }
}

// MARK: - ScanRecord Tests

final class ScanRecordTests: XCTestCase {
    func testScanRecordCreation() {
        let record = ScanRecord(
            barcode: "123",
            productName: "Test",
            dateScanned: Date(),
            safety: .safe
        )

        XCTAssertEqual(record.barcode, "123")
        XCTAssertEqual(record.productName, "Test")
        XCTAssertEqual(record.safety, .safe)
        XCTAssertNil(record.profileId)
    }

    func testScanRecordWithProfile() {
        let profileId = UUID()
        let record = ScanRecord(
            barcode: "456",
            productName: "Test Product",
            dateScanned: Date(),
            safety: .unsafe,
            profileId: profileId
        )

        XCTAssertEqual(record.profileId, profileId)
        XCTAssertEqual(record.safety, .unsafe)
    }

    func testSafetyStatusRawValues() {
        XCTAssertEqual(SafetyStatus.safe.rawValue, "safe")
        XCTAssertEqual(SafetyStatus.unsafe.rawValue, "unsafe")
        XCTAssertEqual(SafetyStatus.unknown.rawValue, "unknown")
    }

    func testScanRecordCodable() throws {
        let record = ScanRecord(
            barcode: "789",
            productName: "Encoded Product",
            dateScanned: Date(),
            safety: .unknown,
            profileId: UUID()
        )

        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(ScanRecord.self, from: data)

        XCTAssertEqual(decoded.barcode, record.barcode)
        XCTAssertEqual(decoded.productName, record.productName)
        XCTAssertEqual(decoded.safety, record.safety)
        XCTAssertEqual(decoded.profileId, record.profileId)
    }
}

// MARK: - CustomAllergen Tests

final class CustomAllergenTests: XCTestCase {
    func testDefaultValues() {
        let allergen = CustomAllergen(name: "Corn")
        XCTAssertEqual(allergen.name, "Corn")
        XCTAssertTrue(allergen.isEnabled)
    }

    func testDisabledAllergen() {
        var allergen = CustomAllergen(name: "Corn")
        allergen.isEnabled = false
        XCTAssertFalse(allergen.isEnabled)
    }

    func testHashable() {
        let allergen1 = CustomAllergen(name: "Corn")
        let allergen2 = CustomAllergen(name: "Corn")
        // Different IDs so they should not be equal
        XCTAssertNotEqual(allergen1, allergen2)
    }

    func testCodable() throws {
        let allergen = CustomAllergen(name: "Corn")
        let data = try JSONEncoder().encode(allergen)
        let decoded = try JSONDecoder().decode(CustomAllergen.self, from: data)
        XCTAssertEqual(decoded.name, allergen.name)
        XCTAssertEqual(decoded.isEnabled, allergen.isEnabled)
        XCTAssertEqual(decoded.id, allergen.id)
    }
}

// MARK: - Ingredient-to-Allergen Mapping Tests

final class IngredientMappingTests: XCTestCase {
    func testDairyMappings() {
        let dairyIngredients = ["casein", "whey", "milk", "dairy", "yogurt", "cheese"]
        for ingredient in dairyIngredients {
            let mapping = ScannerViewModel.ingredientToAllergen[ingredient]
            XCTAssertNotNil(mapping, "Expected mapping for '\(ingredient)'")
            XCTAssertEqual(mapping?.allergen, .dairy, "'\(ingredient)' should map to dairy")
        }
    }

    func testEggMappings() {
        let eggIngredients = ["albumin", "egg", "globulin", "ovalbumin", "lysozyme", "e1105"]
        for ingredient in eggIngredients {
            let mapping = ScannerViewModel.ingredientToAllergen[ingredient]
            XCTAssertNotNil(mapping, "Expected mapping for '\(ingredient)'")
            XCTAssertEqual(mapping?.allergen, .eggs, "'\(ingredient)' should map to eggs")
        }
    }

    func testSoyMappings() {
        let soyIngredients = ["soy", "soya", "soybean", "tofu", "edamame"]
        for ingredient in soyIngredients {
            let mapping = ScannerViewModel.ingredientToAllergen[ingredient]
            XCTAssertNotNil(mapping, "Expected mapping for '\(ingredient)'")
            XCTAssertEqual(mapping?.allergen, .soy, "'\(ingredient)' should map to soy")
        }
    }

    func testNutMappings() {
        let treeNutIngredients = ["almond", "cashew", "walnut", "pecan", "pistachio", "hazelnut"]
        for ingredient in treeNutIngredients {
            let mapping = ScannerViewModel.ingredientToAllergen[ingredient]
            XCTAssertNotNil(mapping, "Expected mapping for '\(ingredient)'")
            XCTAssertEqual(mapping?.allergen, .treeNuts, "'\(ingredient)' should map to treeNuts")
        }
    }

    func testPeanutMappings() {
        let peanutIngredients = ["peanut", "groundnut", "arachis oil"]
        for ingredient in peanutIngredients {
            let mapping = ScannerViewModel.ingredientToAllergen[ingredient]
            XCTAssertNotNil(mapping, "Expected mapping for '\(ingredient)'")
            XCTAssertEqual(mapping?.allergen, .peanuts, "'\(ingredient)' should map to peanuts")
        }
    }

    func testSulfiteMappings() {
        let sulfiteIngredients = ["sulfite", "sulphite", "sulfur dioxide", "e220", "e228"]
        for ingredient in sulfiteIngredients {
            let mapping = ScannerViewModel.ingredientToAllergen[ingredient]
            XCTAssertNotNil(mapping, "Expected mapping for '\(ingredient)'")
            XCTAssertEqual(mapping?.allergen, .sulfites, "'\(ingredient)' should map to sulfites")
        }
    }

    func testFoodDyeMappings() {
        let dyeIngredients = ["red 40", "yellow 5", "blue 1", "e129", "e102"]
        for ingredient in dyeIngredients {
            let mapping = ScannerViewModel.ingredientToAllergen[ingredient]
            XCTAssertNotNil(mapping, "Expected mapping for '\(ingredient)'")
            XCTAssertEqual(mapping?.allergen, .foodDyes, "'\(ingredient)' should map to foodDyes")
        }
    }

    func testShellFishMappings() {
        let shellfishIngredients = ["shrimp", "crab", "lobster", "scallop", "mussel"]
        for ingredient in shellfishIngredients {
            let mapping = ScannerViewModel.ingredientToAllergen[ingredient]
            XCTAssertNotNil(mapping, "Expected mapping for '\(ingredient)'")
            XCTAssertEqual(mapping?.allergen, .shellfish, "'\(ingredient)' should map to shellfish")
        }
    }

    func testMappingExplanationsNotEmpty() {
        for (ingredient, mapping) in ScannerViewModel.ingredientToAllergen {
            XCTAssertFalse(mapping.explanation.isEmpty, "Explanation for '\(ingredient)' should not be empty")
        }
    }
}

// MARK: - ProductError Tests

final class ProductErrorTests: XCTestCase {
    func testProductNotFoundDescription() {
        let error = ProductError.productNotFound
        XCTAssertEqual(error.errorDescription, "Product not found in database.")
    }

    func testInvalidBarcodeDescription() {
        let error = ProductError.invalidBarcode
        XCTAssertEqual(error.errorDescription, "The barcode is invalid. Barcodes should contain only digits.")
    }
}

// MARK: - UserProfile Tests

final class UserProfileTests: XCTestCase {
    func testDefaultProfile() {
        let profile = UserProfile(name: "Test User")
        XCTAssertEqual(profile.name, "Test User")
        XCTAssertEqual(profile.emoji, "👤")
        XCTAssertTrue(profile.selectedAllergens.isEmpty)
        XCTAssertTrue(profile.customAllergens.isEmpty)
    }

    func testProfileWithAllergens() {
        let profile = UserProfile(
            name: "Allergic User",
            emoji: "👧",
            selectedAllergens: [.dairy, .peanuts, .gluten]
        )
        XCTAssertEqual(profile.selectedAllergens.count, 3)
        XCTAssertTrue(profile.selectedAllergens.contains(.dairy))
    }

    func testActiveCustomAllergenNames() {
        let custom1 = CustomAllergen(name: "Corn")
        var custom2 = CustomAllergen(name: "MSG")
        custom2.isEnabled = false
        let custom3 = CustomAllergen(name: "Annatto")

        let profile = UserProfile(
            name: "Test",
            customAllergens: [custom1, custom2, custom3]
        )

        let activeNames = profile.activeCustomAllergenNames
        XCTAssertEqual(activeNames.count, 2)
        XCTAssertTrue(activeNames.contains("Corn"))
        XCTAssertTrue(activeNames.contains("Annatto"))
        XCTAssertFalse(activeNames.contains("MSG"))
    }

    func testCreateDefaultProfile() {
        let profile = UserProfile.createDefaultProfile(
            selectedAllergens: [.dairy, .eggs],
            customAllergens: [CustomAllergen(name: "Corn")]
        )
        XCTAssertEqual(profile.name, "Me")
        XCTAssertEqual(profile.emoji, "👤")
        XCTAssertEqual(profile.selectedAllergens.count, 2)
        XCTAssertEqual(profile.customAllergens.count, 1)
    }

    func testProfileCodable() throws {
        let profile = UserProfile(
            name: "Encoded User",
            emoji: "🧒",
            selectedAllergens: [.fish, .shellfish]
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)

        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.name, profile.name)
        XCTAssertEqual(decoded.emoji, profile.emoji)
        XCTAssertEqual(decoded.selectedAllergens, profile.selectedAllergens)
    }
}

// MARK: - ScanInsights Tests

final class ScanInsightsTests: XCTestCase {
    func testEmptyInsights() {
        let insights = ScanInsights.empty
        XCTAssertEqual(insights.totalScans, 0)
        XCTAssertEqual(insights.safeScans, 0)
        XCTAssertEqual(insights.unsafeScans, 0)
        XCTAssertEqual(insights.unknownScans, 0)
        XCTAssertEqual(insights.safetyRate, 0)
        XCTAssertEqual(insights.unsafeRate, 0)
        XCTAssertTrue(insights.mostScannedProducts.isEmpty)
        XCTAssertTrue(insights.weeklyActivity.isEmpty)
    }

    func testSafetyRateCalculation() {
        let insights = ScanInsights(
            totalScans: 10,
            safeScans: 7,
            unsafeScans: 2,
            unknownScans: 1,
            scansThisWeek: 5,
            scansThisMonth: 10,
            scansToday: 2,
            mostScannedProducts: [],
            recentlyScanned: [],
            allergenAvoided: 2,
            currentStreak: 3,
            longestStreak: 5,
            weeklyActivity: []
        )

        XCTAssertEqual(insights.safetyRate, 0.7, accuracy: 0.001)
        XCTAssertEqual(insights.unsafeRate, 0.2, accuracy: 0.001)
    }

    func testSafetyRateWithZeroScans() {
        let insights = ScanInsights.empty
        XCTAssertEqual(insights.safetyRate, 0)
        XCTAssertEqual(insights.unsafeRate, 0)
    }
}

// MARK: - DayActivity Tests

final class DayActivityTests: XCTestCase {
    func testDayActivityCreation() {
        let date = Date()
        let activity = DayActivity(date: date, scanCount: 5)

        XCTAssertEqual(activity.scanCount, 5)
        XCTAssertFalse(activity.dayName.isEmpty)
    }

    func testDayNameFormat() {
        // Create a known date (a Monday)
        var components = DateComponents()
        components.year = 2025
        components.month = 8
        components.day = 11 // Monday
        let monday = Calendar.current.date(from: components)!

        let activity = DayActivity(date: monday, scanCount: 1)
        XCTAssertEqual(activity.dayName, "Mon")
    }
}

// MARK: - ExportFormat Tests

final class ExportFormatTests: XCTestCase {
    func testAllCasesCount() {
        XCTAssertEqual(ExportFormat.allCases.count, 3)
    }

    func testFileExtensions() {
        XCTAssertEqual(ExportFormat.text.fileExtension, "txt")
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.pdf.fileExtension, "pdf")
    }

    func testIcons() {
        XCTAssertFalse(ExportFormat.text.icon.isEmpty)
        XCTAssertFalse(ExportFormat.csv.icon.isEmpty)
        XCTAssertFalse(ExportFormat.pdf.icon.isEmpty)
    }

    func testDescriptions() {
        XCTAssertFalse(ExportFormat.text.description.isEmpty)
        XCTAssertFalse(ExportFormat.csv.description.isEmpty)
        XCTAssertFalse(ExportFormat.pdf.description.isEmpty)
    }
}

// MARK: - InsightsTimePeriod Tests

final class InsightsTimePeriodTests: XCTestCase {
    func testDisplayNames() {
        XCTAssertEqual(InsightsTimePeriod.week.displayName, "This Week")
        XCTAssertEqual(InsightsTimePeriod.month.displayName, "This Month")
        XCTAssertEqual(InsightsTimePeriod.allTime.displayName, "All Time")
    }
}
