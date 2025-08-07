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
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .foregroundColor(.primary)
            .clipShape(Capsule())
            .transition(.scale.combined(with: .opacity))
    }
}
