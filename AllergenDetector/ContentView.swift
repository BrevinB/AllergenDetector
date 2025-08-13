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
    @State private var manualBarcode = ""
    @State private var scanStatusMessage = "Align the barcode within the frame"

    // MARK: - Subviews for Animations

    @ViewBuilder
    private var allergenChipsView: some View {
        if !settings.selectedAllergens.isEmpty || !settings.activeCustomAllergenNames.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(settings.selectedAllergens.sorted(by: { $0.displayName < $1.displayName })) { allergen in
                        AllergenChip(label: allergen.displayName)
                    }

                    ForEach(settings.activeCustomAllergenNames.sorted(), id: \.self) { custom in
                        AllergenChip(label: custom)
                    }
                }
                .padding(.horizontal)
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
                matchDetails: viewModel.matchDetails,
                allergenStatuses: viewModel.allergenStatuses,
                customAllergenStatuses: viewModel.customAllergenStatuses,
                safetyStatus: viewModel.lastScanSafety ?? .unknown
            )
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7),
                value: viewModel.scannedProduct?.barcode
            )
        }
    }

    private func startScanFeedback() {
        scanStatusMessage = "Align the barcode within the frame"
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isShowingScanner {
                scanStatusMessage = "No barcode detected. Try again or enter the code manually."
            }
        }
    }

    private func handleSelectedAllergensChange() {
        for key in Array(viewModel.allergenStatuses.keys) {
            if !settings.selectedAllergens.contains(key) {
                viewModel.allergenStatuses.removeValue(forKey: key)
            }
        }
        viewModel.matchDetails.removeAll { detail in
            let contains: Bool
            if let allergen = detail.allergen {
                contains = !settings.selectedAllergens.contains(allergen)
            } else {
                contains = false
            }
            return contains
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // MARK: Selected Allergen Chips (animated)
                allergenChipsView

                // MARK: Scan Button
                
                Spacer()
                

                // MARK: Last Scanned Product Card (spring‐animate its appearance)
                scannedProductCardView

        
                Spacer()
                scanButtonView
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
                BarcodeScannerSheet(
                    isShowing: $isShowingScanner,
                    manualBarcode: $manualBarcode,
                    viewModel: viewModel,
                    scanStatusMessage: scanStatusMessage,
                    onScanStatusUpdate: startScanFeedback
                )
                .environmentObject(settings)
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
            .onChange(of: settings.selectedAllergens) { _ in
                handleSelectedAllergensChange()
            }
            .onChange(of: settings.customAllergens) { _ in
                let active = settings.activeCustomAllergenNames
                for key in Array(viewModel.customAllergenStatuses.keys) {
                    if !active.contains(key) {
                        viewModel.customAllergenStatuses.removeValue(forKey: key)
                    }
                }
                viewModel.matchDetails.removeAll { detail in
                    detail.allergen == nil && !active.contains(detail.allergenName)
                }
            }
        }
    }
}

struct ProductCardView: View {
    let product: Product
    let selectedAllergens: Set<Allergen>
    let matchDetails: [ScannerViewModel.AllergenMatchDetail]
    let allergenStatuses: [Allergen: Bool]
    let customAllergenStatuses: [String: Bool]
    let safetyStatus: SafetyStatus

    var body: some View {
        let icon: String
        let title: String
        let bannerColor: Color
        switch safetyStatus {
        case .safe:
            icon = "checkmark.shield.fill"
            title = "Safe to Eat"
            bannerColor = Color(.systemGreen)
        case .unsafe:
            icon = "exclamationmark.triangle.fill"
            title = "Warning!"
            bannerColor = Color(.systemRed)
        case .unknown:
            icon = "questionmark.diamond.fill"
            title = "Unknown Safety"
            bannerColor = Color(.systemOrange)
        }

        return VStack(spacing: 0) {
            // HEADER BANNER - shows safety based on combined logic of allergens and matchDetails
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(product.productName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(bannerColor)

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
                    // Combine allergens from product.allergens (filtered by selectedAllergens)
                    // and any found via ingredient matching or custom allergens
                    let productAllergensSet = Set(
                        product.allergens
                            .filter { selectedAllergens.contains($0) }
                            .map { $0.displayName }
                    )
                    let matchAllergensSet = Set(matchDetails.map { $0.allergenName })
                    let uniqueAllergens = productAllergensSet.union(matchAllergensSet)

                    if uniqueAllergens.isEmpty {
                        Text("None Found")
                            .font(.subheadline)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(uniqueAllergens), id: \.self) { name in
                                Text("• \(name)")
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                if !allergenStatuses.isEmpty || !customAllergenStatuses.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Allergen Results:")
                            .font(.subheadline.weight(.semibold))
                        ForEach(Array(selectedAllergens).sorted { $0.displayName < $1.displayName }) { allergen in
                            HStack {
                                Image(systemName: allergenStatuses[allergen] == true ? "checkmark.circle" : "xmark.octagon")
                                    .foregroundColor(allergenStatuses[allergen] == true ? .green : .red)
                                Text(allergen.displayName)
                            }
                            .font(.subheadline)
                        }
                        ForEach(customAllergenStatuses.keys.sorted(), id: \.self) { name in
                            HStack {
                                let safe = customAllergenStatuses[name] == true
                                Image(systemName: safe ? "checkmark.circle" : "xmark.octagon")
                                    .foregroundColor(safe ? .green : .red)
                                Text(name)
                            }
                            .font(.subheadline)
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
                        Text("\u{2022} \(detail.ingredient): \(detail.allergenName) — \(detail.explanation)")
                            .font(.footnote)
                    }
                }
                .padding([.top, .horizontal])
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSettings()) // Assuming UserSettings environment object is required
}

// Note: ProductCardView requires matchDetails parameter, ContentView passes it from viewModel.matchDetails.
// The preview ContentView uses empty UserSettings() for environment object, no direct ProductCardView preview provided here.

