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
                            var updated = settings.selectedAllergens
                            if newValue {
                                updated.insert(allergen)
                            } else {
                                updated.remove(allergen)
                            }
                            settings.updateSelectedAllergens(updated)
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
                    var updated = settings.customAllergens
                    updated.remove(atOffsets: indexSet)
                    settings.updateCustomAllergens(updated)
                }

                HStack {
                    TextField("Add allergen", text: $newCustom)
                    Button("Add") {
                        let trimmed = newCustom.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        guard trimmed.count <= 50 else { return }
                        let isDuplicate = settings.customAllergens.contains {
                            $0.name.lowercased() == trimmed.lowercased()
                        }
                        guard !isDuplicate else { return }
                        var updated = settings.customAllergens
                        updated.append(CustomAllergen(name: trimmed))
                        settings.updateCustomAllergens(updated)
                        newCustom = ""
                    }
                }
            }
        }
        .navigationTitle("Allergens")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear All") {
                    settings.updateSelectedAllergens([])
                    settings.updateCustomAllergens([])
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
        return Binding(
            get: { settings.customAllergens[index].isEnabled },
            set: { newValue in
                var updated = settings.customAllergens
                updated[index].isEnabled = newValue
                settings.updateCustomAllergens(updated)
            }
        )
    }
}

#Preview {
    AllergenSelectionView()
}
