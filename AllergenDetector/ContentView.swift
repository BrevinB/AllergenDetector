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
                .font(.title3)
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


    var body: some View {
        NavigationView {
            ScrollView {
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
            }}
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
                viewModel.reevaluateCurrentProduct(
                    selectedAllergens: settings.selectedAllergens,
                    customAllergens: settings.activeCustomAllergenNames
                )
            }
            .onChange(of: settings.customAllergens) { _ in
                viewModel.reevaluateCurrentProduct(
                    selectedAllergens: settings.selectedAllergens,
                    customAllergens: settings.activeCustomAllergenNames
                )
            }
        }
    }
}

struct ProductCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAllergens = true
    @State private var showReasons = false

    let product: Product
    let selectedAllergens: Set<Allergen>
    let matchDetails: [ScannerViewModel.AllergenMatchDetail]
    let allergenStatuses: [Allergen: Bool]
    let customAllergenStatuses: [String: Bool]
    let safetyStatus: SafetyStatus

    var body: some View {
        // Header config
        let icon: String
        let title: String
        let bannerBase: Color
        switch safetyStatus {
        case .safe:    icon = "checkmark.shield.fill";      title = "Safe to Eat";    bannerBase = Color(.systemGreen)
        case .unsafe:  icon = "exclamationmark.triangle.fill"; title = "Warning!";    bannerBase = Color(.systemRed)
        case .unknown: icon = "questionmark.diamond.fill";  title = "Unknown Safety"; bannerBase = Color(.systemOrange)
        }

        // Card styling (dark vs light)
        let cardFill: some ShapeStyle =
            colorScheme == .dark ? AnyShapeStyle(.regularMaterial)
                                 : AnyShapeStyle(Color(.systemBackground))
        let cardStroke = colorScheme == .dark ? Color.white.opacity(0.10)
                                              : Color.black.opacity(0.06)
        let dropShadow = colorScheme == .dark ? Color.black.opacity(0.70)
                                              : Color.black.opacity(0.15)

        // Build combined allergen list for the chip grid (flagged first)
        let allItems: [AllergenItem] = {
            var items = Array(selectedAllergens).map {
                AllergenItem(name: $0.displayName, isSafe: allergenStatuses[$0] == true)
            }
            items += customAllergenStatuses.map { .init(name: $0.key, isSafe: $0.value) }
            // flagged first, then alpha
            return items.sorted { (lhs, rhs) in
                if lhs.isSafe != rhs.isSafe { return !lhs.isSafe && rhs.isSafe }
                return lhs.name < rhs.name
            }
        }()

        let flaggedCount = allItems.filter { !$0.isSafe }.count
        let safeCount = allItems.count - flaggedCount

        return VStack(spacing: 0) {
            // HEADER
            HStack {
                Image(systemName: icon).foregroundColor(.white)
                Text(title).font(.title3).foregroundColor(.white)
                Spacer()
                Text(product.productName)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [bannerBase.opacity(0.98), bannerBase.opacity(0.85)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedCornerShape(radius: 12, corners: [.topLeft, .topRight]))
                    .shadow(color: bannerBase.opacity(colorScheme == .dark ? 0.45 : 0.25),
                            radius: colorScheme == .dark ? 20 : 10, x: 0, y: 8)
            )

            // MAIN CONTENT
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Name:").font(.body.weight(.semibold))
                    Text(product.productName)
                    Spacer()
                }

                HStack(alignment: .top, spacing: 6) {
                    Text("Allergens:").font(.body.weight(.semibold))

                    let productAllergensSet = Set(product.allergens.filter { selectedAllergens.contains($0) }.map { $0.displayName })
                    let matchAllergensSet = Set(matchDetails.map { $0.allergenName })
                    let uniqueAllergens = productAllergensSet.union(matchAllergensSet)

                    if uniqueAllergens.isEmpty {
                        Text("None Found")
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(uniqueAllergens).sorted(), id: \.self) { name in
                                Text("• \(name)")
                            }
                        }
                    }
                }

                // SELECTED RESULTS — chips in an adaptive grid inside a DisclosureGroup
                if !allItems.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        DisclosureGroup(
                            "Selected Allergen Results (\(flaggedCount) flagged, \(safeCount) safe)",
                            isExpanded: $showAllergens
                        ) {
                            let cols = [GridItem(.adaptive(minimum: 120), spacing: 8)]
                            LazyVGrid(columns: cols, spacing: 8) {
                                ForEach(allItems) { item in
                                    AllergenChips(name: item.name, isSafe: item.isSafe)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .font(.body.weight(.semibold))
                        .tint(.primary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, matchDetails.isEmpty ? 12 : 0)

            // WHY FLAGGED — collapse if long
            if !matchDetails.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    DisclosureGroup("Why flagged? (\(matchDetails.count))", isExpanded: $showReasons) {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(matchDetails.indices, id: \.self) { i in
                                let d = matchDetails[i]
                                Text("• \(d.ingredient): \(d.allergenName) — \(d.explanation)")
                                    .font(.callout)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .font(.body.weight(.bold))
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardStroke, lineWidth: 1)
                )
                .shadow(color: dropShadow, radius: 22, x: 0, y: 16)
        )
    }
}

private struct AllergenItem: Identifiable {
    let id = UUID()
    let name: String
    let isSafe: Bool
}

private struct AllergenChips: View {
    @Environment(\.colorScheme) private var scheme
    let name: String
    let isSafe: Bool

    var body: some View {
        let fillColor: Color = isSafe
            ? (scheme == .dark ? Color.green.opacity(0.18) : Color.green.opacity(0.12))
            : (scheme == .dark ? Color.red.opacity(0.22) : Color.red.opacity(0.14))
        let strokeColor: Color = isSafe
            ? Color.green.opacity(scheme == .dark ? 0.55 : 0.35)
            : Color.red.opacity(scheme == .dark ? 0.55 : 0.35)
        let foreground: Color = isSafe ? Color.green : Color.red

        HStack(spacing: 6) {
            Image(systemName: isSafe ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .imageScale(.small)
            Text(name)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(fillColor)
        )
        .overlay(
            Capsule()
                .stroke(strokeColor, lineWidth: 1)
        )
        .foregroundStyle(foreground)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSettings()) // Assuming UserSettings environment object is required
}

// Note: ProductCardView requires matchDetails parameter, ContentView passes it from viewModel.matchDetails.
// The preview ContentView uses empty UserSettings() for environment object, no direct ProductCardView preview provided here.

struct RoundedCornerShape: Shape {
    var radius: CGFloat = 12
    var corners: UIRectCorner = [.topLeft, .topRight]
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

