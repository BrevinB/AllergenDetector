//
//  Theme.swift
//  AllergenDetector
//
//  Central theme definition — brand colors, gradients, and reusable view modifiers
//

import SwiftUI

// MARK: - Brand Colors

extension Color {
    // Primary brand palette — teal/green conveying health & trust
    static let brand = Color(red: 0.11, green: 0.61, blue: 0.55)        // #1B9B8C
    static let brandDark = Color(red: 0.05, green: 0.37, blue: 0.33)    // #0D5E55
    static let brandLight = Color(red: 0.88, green: 0.96, blue: 0.94)   // #E0F5F0

    // Safety status colors
    static let safeGreen = Color(red: 0.20, green: 0.78, blue: 0.35)    // #34C759
    static let warningRed = Color(red: 1.00, green: 0.23, blue: 0.36)   // #FF3B5C
    static let cautionAmber = Color(red: 1.00, green: 0.69, blue: 0.13) // #FFB020

    // Neutral tones
    static let surfaceLight = Color(red: 0.97, green: 0.98, blue: 0.98) // #F8FAFA
    static let surfaceDark = Color(red: 0.11, green: 0.13, blue: 0.15)  // #1C2126

    /// Returns the appropriate surface color for the current color scheme.
    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .surfaceDark : .surfaceLight
    }
}

// MARK: - Brand Gradients

extension LinearGradient {
    static let brandGradient = LinearGradient(
        colors: [.brand, .brandDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let safeGradient = LinearGradient(
        colors: [Color.safeGreen, Color.safeGreen.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warningGradient = LinearGradient(
        colors: [Color.warningRed, Color.warningRed.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cautionGradient = LinearGradient(
        colors: [Color.cautionAmber, Color.cautionAmber.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let shimmer = LinearGradient(
        colors: [.brand.opacity(0.15), .brand.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Reusable View Modifiers

struct ThemedCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color(.systemBackground)))
                    .shadow(color: colorScheme == .dark ? .black.opacity(0.5) : .brand.opacity(0.08), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.brand.opacity(0.1), lineWidth: 1)
            )
    }
}

struct ThemedSectionHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3.weight(.bold))
            .foregroundStyle(Color.brand)
    }
}

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }

    func themedSectionHeader() -> some View {
        modifier(ThemedSectionHeader())
    }
}

// MARK: - Branded Button Style

struct BrandedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(LinearGradient.brandGradient)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
                    .shadow(color: .brand.opacity(0.35), radius: 10, x: 0, y: 5)
            )
    }
}

extension ButtonStyle where Self == BrandedButtonStyle {
    static var branded: BrandedButtonStyle { BrandedButtonStyle() }
}

// MARK: - Safety Status Helpers

extension SafetyStatus {
    var themeColor: Color {
        switch self {
        case .safe: return .safeGreen
        case .unsafe: return .warningRed
        case .unknown: return .cautionAmber
        }
    }

    var themeGradient: LinearGradient {
        switch self {
        case .safe: return .safeGradient
        case .unsafe: return .warningGradient
        case .unknown: return .cautionGradient
        }
    }

    var themeIcon: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .unsafe: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.diamond.fill"
        }
    }

    var themeLabel: String {
        switch self {
        case .safe: return "Safe to Eat"
        case .unsafe: return "Warning!"
        case .unknown: return "Unknown Safety"
        }
    }
}
