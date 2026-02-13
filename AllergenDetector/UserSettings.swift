//
//  UserSettings.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 5/30/25.
//
//  Now acts as a facade over ProfileManager for the active profile
//

import Foundation
import Combine

class UserSettings: ObservableObject {
    private let profileManager = ProfileManager.shared
    private var cancellables = Set<AnyCancellable>()

    @Published var selectedAllergens: Set<Allergen> = []
    @Published var customAllergens: [CustomAllergen] = []

    init() {
        // Listen to profile manager changes and update published properties
        profileManager.$profiles
            .sink { [weak self] _ in
                self?.refreshFromActiveProfile()
            }
            .store(in: &cancellables)

        profileManager.$activeProfileId
            .sink { [weak self] _ in
                self?.refreshFromActiveProfile()
            }
            .store(in: &cancellables)

        // Initial load
        refreshFromActiveProfile()
    }

    /// Refreshes the published properties from the active profile
    private func refreshFromActiveProfile() {
        if let active = profileManager.activeProfile {
            selectedAllergens = active.selectedAllergens
            customAllergens = active.customAllergens
        } else {
            selectedAllergens = []
            customAllergens = []
        }
    }

    /// Updates the active profile's selected allergens
    func updateSelectedAllergens(_ allergens: Set<Allergen>) {
        guard var profile = profileManager.activeProfile else { return }
        profile.selectedAllergens = allergens
        profileManager.updateProfile(profile)
        selectedAllergens = allergens
    }

    /// Updates the active profile's custom allergens
    func updateCustomAllergens(_ allergens: [CustomAllergen]) {
        guard var profile = profileManager.activeProfile else { return }
        profile.customAllergens = allergens
        profileManager.updateProfile(profile)
        customAllergens = allergens
    }

    var activeCustomAllergenNames: [String] {
        customAllergens.filter { $0.isEnabled }.map { $0.name }
    }
}
