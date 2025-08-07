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
    @State private var newCustom = ""

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

            Section(header: Text("Custom Allergens")) {
                ForEach(settings.customAllergens) { allergen in
                    Toggle(allergen.name, isOn: binding(for: allergen))
                }
                .onDelete { indexSet in
                    settings.customAllergens.remove(atOffsets: indexSet)
                }

                HStack {
                    TextField("Add allergen", text: $newCustom)
                    Button("Add") {
                        let trimmed = newCustom.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        settings.customAllergens.append(CustomAllergen(name: trimmed))
                        newCustom = ""
                    }
                }
            }
        }
        .navigationTitle("Allergens")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear All") {
                    settings.selectedAllergens.removeAll()
                    settings.customAllergens.removeAll()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for allergen: CustomAllergen) -> Binding<Bool> {
        guard let index = settings.customAllergens.firstIndex(of: allergen) else {
            return .constant(allergen.isEnabled)
        }
        return $settings.customAllergens[index].isEnabled
    }
}

#Preview {
    AllergenSelectionView()
}
