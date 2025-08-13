//
//  AllergenChip.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 8/6/25.
//

import SwiftUI

struct AllergenChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.subheadline.weight(.semibold))
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
