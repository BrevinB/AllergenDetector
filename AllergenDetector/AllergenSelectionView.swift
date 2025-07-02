//
//  AllergenSelectionView.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 5/30/25.
//

import SwiftUI

struct AllergenSelectionView: View {
    @EnvironmentObject var settings: UserSettings
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Avoid These Allergens")
                        .font(.headline)
                        .foregroundColor(.primary)
            ) {
                ForEach(Allergen.allCases) { allergen in
                    Toggle(isOn: Binding(
                        get: { settings.selectedAllergens.contains(allergen) },
                        set: { newValue in
                            if newValue {
                                settings.selectedAllergens.insert(allergen)
                            } else {
                                settings.selectedAllergens.remove(allergen)
                            }
                        }
                    )) {
                        Text(allergen.displayName)
                    }
                }
            }
        }
        .navigationTitle("Allergens")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear All") {
                    settings.selectedAllergens.removeAll()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AllergenSelectionView()
}
