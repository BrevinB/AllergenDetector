//
//  ContentView.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 5/30/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject private var viewModel = ScannerViewModel()
    @State private var isShowingScanner = false
    @State private var pulse = false  // For button pulse animation

    // MARK: - Subviews for Animations

    @ViewBuilder
    private var allergenChipsView: some View {
        if !settings.selectedAllergens.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(settings.selectedAllergens)) { allergen in
                        Text(allergen.displayName)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.3), value: settings.selectedAllergens)
            }
        } else {
            Text("No allergens selected")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .padding(.horizontal)
        }
    }

    private var scanButtonView: some View {
        Button {
            isShowingScanner = true
            pulse = false
        } label: {
            Label("Scan Barcode", systemImage: "barcode.viewfinder")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var scannedProductCardView: some View {
        if let product = viewModel.scannedProduct {
            ProductCardView(
                product: product,
                selectedAllergens: settings.selectedAllergens,
                matchDetails: viewModel.matchDetails
            )
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7),
                value: viewModel.scannedProduct?.barcode
            )
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // MARK: Selected Allergen Chips (animated)
                allergenChipsView

                // MARK: Scan Button
                scanButtonView

                Spacer()

                // MARK: Last Scanned Product Card (spring‐animate its appearance)
                scannedProductCardView

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Allergen Detector")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: HistoryView()) {
                        Label("History", systemImage: "clock.fill")
                    }
                }
                
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AllergenSelectionView()) {
                        Label("Allergens", systemImage: "list.bullet.clipboard")
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    VStack(spacing: 0) {
                        BarcodeScannerView { code in
                            viewModel.handleBarcode(
                                code,
                                selectedAllergens: settings.selectedAllergens
                            )
                            isShowingScanner = false
                        }
                        .frame(height: 350)

                        HStack {
                            Spacer()
                            Button(role: .cancel) {
                                isShowingScanner = false
                            } label: {
                                Label("Cancel", systemImage: "xmark.circle")
                            }
                            .font(.headline)
                            .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding()
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Result"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                        .scaleEffect(1.5)
                }
            }
            .onAppear {
                // Start the pulse animation when the view appears
                withAnimation {
                    pulse.toggle()
                }
            }
        }
    }
}

struct ProductCardView: View {
    let product: Product
    let selectedAllergens: Set<Allergen>
    let matchDetails: [ScannerViewModel.AllergenMatchDetail]

    // Updated isSafe logic: product.allergens disjoint with selectedAllergens AND no matchDetails
    var isSafe: Bool {
        Set(product.allergens).isDisjoint(with: selectedAllergens) && matchDetails.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // HEADER BANNER - shows safety based on combined logic of allergens and matchDetails
            HStack {
                Image(systemName: isSafe ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text(isSafe ? "Safe to Eat" : "Warning!")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(product.productName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(isSafe ? Color(.systemGreen) : Color(.systemRed))

            // MAIN CONTENT
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Name:")
                        .font(.subheadline.weight(.semibold))
                    Text(product.productName)
                        .font(.subheadline)
                    Spacer()
                }
                HStack(alignment: .top) {
                    Text("Allergens:")
                        .font(.subheadline.weight(.semibold))
                    // Combine allergens from product.allergens (filtered by selectedAllergens) and matchDetails.allergen, showing unique allergens
                    let productAllergensSet = Set(product.allergens).intersection(selectedAllergens)
                    let matchAllergensSet = Set(matchDetails.map { $0.allergen })
                    let uniqueAllergens = productAllergensSet.union(matchAllergensSet)

                    if uniqueAllergens.isEmpty {
                        Text("None Found")
                            .font(.subheadline)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(uniqueAllergens)) { allergen in
                                Text("• \(allergen.displayName)")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding()
            
            if !matchDetails.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Why flagged?")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)
                    ForEach(matchDetails.indices, id: \.self) { idx in
                        let detail = matchDetails[idx]
                        Text("\u{2022} \(detail.ingredient): \(detail.allergen.displayName) — \(detail.explanation)")
                            .font(.footnote)
                    }
                }
                .padding([.top, .horizontal])
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSettings()) // Assuming UserSettings environment object is required
}

// Note: ProductCardView requires matchDetails parameter, ContentView passes it from viewModel.matchDetails.
// The preview ContentView uses empty UserSettings() for environment object, no direct ProductCardView preview provided here.

