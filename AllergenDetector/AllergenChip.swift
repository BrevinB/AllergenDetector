//
//  AllergenChip.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 8/6/25.
//

import SwiftUI

struct AllergenChip: View {
    let label: String

    private var iconName: String? {
        switch label {
        case "Gluten": return "leaf" // Represent grains
        case "Dairy": return "drop.fill" // Milk droplet
        case "Peanuts": return "peanut" // SF Symbol for peanuts
        case "Tree Nuts", "Nuts": return "leaf.fill"
        case "Eggs": return "egg.fill"
        case "Soy": return "leaf.circle"
        default: return nil
        }
    }

    var body: some View {
        Group {
            if let iconName = iconName {
                Label(label, systemImage: iconName)
            } else {
                Text(label)
            }
        }
        .font(.headline.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.2))
        )
        .overlay(
            Capsule()
                .stroke(Color.accentColor, lineWidth: 1)
        )
        .foregroundColor(.accentColor)
        .transition(.scale.combined(with: .opacity))
    }
}
