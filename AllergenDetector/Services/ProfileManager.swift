//
//  ProfileManager.swift
//  AllergenDetector
//
//  Service to manage multiple user profiles with allergen preferences
//

import Foundation
import Combine

/// Manages multiple user profiles and handles profile switching
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published var profiles: [UserProfile] = []
    @Published var activeProfileId: UUID?

    private let profilesKey = "UserProfiles"
    private let activeProfileKey = "ActiveProfileId"

    /// Computed property for the currently active profile
    var activeProfile: UserProfile? {
        get {
            guard let id = activeProfileId else { return nil }
            return profiles.first { $0.id == id }
        }
        set {
            if let profile = newValue {
                activeProfileId = profile.id
                saveActiveProfileId()
            }
        }
    }

    private init() {
        load()
        migrateFromLegacyIfNeeded()
    }

    // MARK: - Profile Management

    /// Adds a new profile to the list
    func addProfile(_ profile: UserProfile) {
        profiles.append(profile)
        save()

        // If this is the first profile, make it active
        if profiles.count == 1 {
            activeProfileId = profile.id
            saveActiveProfileId()
        }
    }

    /// Updates an existing profile
    func updateProfile(_ profile: UserProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updated = profile
            updated.dateModified = Date()
            profiles[index] = updated
            save()
        }
    }

    /// Deletes a profile by ID
    func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id }

        // If we deleted the active profile, switch to another one
        if activeProfileId == id {
            activeProfileId = profiles.first?.id
            saveActiveProfileId()
        }

        save()
    }

    /// Switches to a different profile
    func switchToProfile(id: UUID) {
        if profiles.contains(where: { $0.id == id }) {
            activeProfileId = id
            saveActiveProfileId()
        }
    }

    // MARK: - Persistence

    private func load() {
        // Load profiles
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([UserProfile].self, from: data) {
            profiles = decoded
        } else {
            profiles = []
        }

        // Load active profile ID
        if let data = UserDefaults.standard.data(forKey: activeProfileKey),
           let decoded = try? JSONDecoder().decode(UUID.self, from: data) {
            activeProfileId = decoded
        } else {
            activeProfileId = profiles.first?.id
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }

    private func saveActiveProfileId() {
        if let id = activeProfileId,
           let data = try? JSONEncoder().encode(id) {
            UserDefaults.standard.set(data, forKey: activeProfileKey)
        }
    }

    // MARK: - Migration

    /// Migrates from the old single-user UserSettings to the new profile system
    private func migrateFromLegacyIfNeeded() {
        // Only migrate if we have no profiles but legacy data exists
        guard profiles.isEmpty else { return }

        // Check for legacy allergen selections
        if let data = UserDefaults.standard.data(forKey: "SelectedAllergens"),
           let selectedAllergens = try? JSONDecoder().decode(Set<Allergen>.self, from: data) {

            var customAllergens: [CustomAllergen] = []
            if let customData = UserDefaults.standard.data(forKey: "CustomAllergens"),
               let decoded = try? JSONDecoder().decode([CustomAllergen].self, from: customData) {
                customAllergens = decoded
            }

            // Create a default profile with the legacy data
            let defaultProfile = UserProfile.createDefaultProfile(
                selectedAllergens: selectedAllergens,
                customAllergens: customAllergens
            )

            addProfile(defaultProfile)
            print("✅ Migrated legacy allergen settings to new profile system")
        } else {
            // No legacy data, create an empty default profile
            let emptyProfile = UserProfile(name: "Me", emoji: "👤")
            addProfile(emptyProfile)
            print("✅ Created initial default profile")
        }
    }
}
