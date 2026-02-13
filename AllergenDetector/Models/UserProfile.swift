//
//  UserProfile.swift
//  AllergenDetector
//
//  Family profiles feature - allows multiple users to maintain separate allergen preferences
//

import Foundation

/// Represents a user profile with their own allergen preferences and settings
struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var emoji: String  // Fun visual identifier (e.g., "👨", "👧", "👶")
    var selectedAllergens: Set<Allergen>
    var customAllergens: [CustomAllergen]
    var dateCreated: Date
    var dateModified: Date

    /// Computed property for active custom allergen names
    var activeCustomAllergenNames: [String] {
        customAllergens.filter { $0.isEnabled }.map { $0.name }
    }

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String = "👤",
        selectedAllergens: Set<Allergen> = [],
        customAllergens: [CustomAllergen] = [],
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.selectedAllergens = selectedAllergens
        self.customAllergens = customAllergens
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    /// Creates a default profile for migration from legacy single-user setup
    static func createDefaultProfile(
        selectedAllergens: Set<Allergen>,
        customAllergens: [CustomAllergen]
    ) -> UserProfile {
        return UserProfile(
            name: "Me",
            emoji: "👤",
            selectedAllergens: selectedAllergens,
            customAllergens: customAllergens
        )
    }
}
