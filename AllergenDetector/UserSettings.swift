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
    @Published var customAllergens: [String] {
        didSet {
            saveCustom()
        }
    }

    private let defaultsKey = "SelectedAllergens"
    private let customKey = "CustomAllergens"
    private let cloud = NSUbiquitousKeyValueStore.default

    init() {
        cloud.synchronize()

        if let data = cloud.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode(Set<Allergen>.self, from: data) {
            selectedAllergens = saved
        } else if let data = UserDefaults.standard.data(forKey: defaultsKey),
                  let saved = try? JSONDecoder().decode(Set<Allergen>.self, from: data) {
            selectedAllergens = saved
        } else {
            selectedAllergens = []
        }

        if let array = cloud.array(forKey: customKey) as? [String] {
            customAllergens = array
        } else if let array = UserDefaults.standard.stringArray(forKey: customKey) {
            customAllergens = array
        } else {
            customAllergens = []
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudChanged(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud
        )
    }

    private func save() {
        if let data = try? JSONEncoder().encode(selectedAllergens) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
            cloud.set(data, forKey: defaultsKey)
            cloud.synchronize()
        }
    }

    private func saveCustom() {
        UserDefaults.standard.set(customAllergens, forKey: customKey)
        cloud.set(customAllergens, forKey: customKey)
        cloud.synchronize()
    }

    @objc private func iCloudChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }

        if keys.contains(defaultsKey),
           let data = cloud.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode(Set<Allergen>.self, from: data),
           saved != selectedAllergens {
            selectedAllergens = saved
        }

        if keys.contains(customKey),
           let array = cloud.array(forKey: customKey) as? [String],
           array != customAllergens {
            customAllergens = array
        }
    }
}
