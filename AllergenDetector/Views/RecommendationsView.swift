//
//  RecommendationsView.swift
//  AllergenDetector
//
//  UI for displaying product recommendations
//

import SwiftUI

struct RecommendationsView: View {
    let originalProduct: Product
    let selectedAllergens: Set<Allergen>
    let customAllergens: [String]

    @State private var recommendations: [ProductRecommendation] = []
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header - Original Product
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)

                        Text("Product Contains Allergens")
                            .font(.title3.bold())

                        Text(originalProduct.productName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Here are some safe alternatives:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)

                    // Recommendations List
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)

                            Text("Finding safe alternatives...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else if recommendations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)

                            Text("No Alternatives Found")
                                .font(.headline)

                            Text("We couldn't find similar products that match your allergen preferences. Try scanning other products in the same category.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, recommendation in
                                RecommendationCard(
                                    recommendation: recommendation,
                                    rank: index + 1
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Safe Alternatives")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .task {
            await loadRecommendations()
        }
    }

    private func loadRecommendations() async {
        isLoading = true

        let results = await RecommendationService.shared.findAlternatives(
            for: originalProduct,
            avoidingAllergens: selectedAllergens,
            customAllergens: customAllergens
        )

        recommendations = results
        isLoading = false
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: ProductRecommendation
    let rank: Int
    @State private var showingDetails = false

    var body: some View {
        Button(action: {
            showingDetails = true
        }) {
            HStack(spacing: 12) {
                // Rank Badge
                ZStack {
                    Circle()
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text("#\(rank)")
                        .font(.caption.bold())
                        .foregroundColor(rankColor)
                }

                // Product Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.productName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if let category = recommendation.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Match Score
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < starCount ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }

                        Text("\(Int(recommendation.matchScore * 100))% match")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Safe Indicator
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                    .imageScale(.large)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Product Details", isPresented: $showingDetails) {
            Button("OK") {}
        } message: {
            Text("Barcode: \(recommendation.barcode)\n\nScan this product to see full details and verify it's safe for you.")
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        default: return .gray
        }
    }

    private var starCount: Int {
        Int((recommendation.matchScore * 5).rounded())
    }
}

#Preview {
    let sampleProduct = Product(
        barcode: "123456",
        productName: "Oreo Cookies",
        allergens: [.dairy],
        ingredients: ["flour", "sugar", "milk"]
    )

    return RecommendationsView(
        originalProduct: sampleProduct,
        selectedAllergens: [.dairy],
        customAllergens: []
    )
}
