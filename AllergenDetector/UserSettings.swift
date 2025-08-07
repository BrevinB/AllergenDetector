//
//  UserSettings.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 5/30/25.
//

import Foundation
import Combine

class UserSettings: ObservableObject {
    @Published var selectedAllergens: Set<Allergen> {
        didSet {
            save()
        }
    }
    @Published var customAllergens: [CustomAllergen] {
        didSet {
            saveCustom()
        }
    }

    private let defaultsKey = "SelectedAllergens"
    private let customKey = "CustomAllergens"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode(Set<Allergen>.self, from: data) {
            selectedAllergens = saved
        } else {
            selectedAllergens = []
        }

        if let data = UserDefaults.standard.data(forKey: customKey),
           let array = try? JSONDecoder().decode([CustomAllergen].self, from: data) {
            customAllergens = array
        } else {
            customAllergens = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(selectedAllergens) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func saveCustom() {
        if let data = try? JSONEncoder().encode(customAllergens) {
            UserDefaults.standard.set(data, forKey: customKey)
        }
    }

    var activeCustomAllergenNames: [String] {
        customAllergens.filter { $0.isEnabled }.map { $0.name }
    }
}
