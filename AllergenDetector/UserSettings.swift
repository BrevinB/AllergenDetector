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

    private let defaultsKey = "SelectedAllergens"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode(Set<Allergen>.self, from: data) {
            selectedAllergens = saved
        } else {
            selectedAllergens = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(selectedAllergens) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
