//
//  BarcodeScannerSheet.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 8/6/25.
//

import SwiftUI

struct BarcodeScannerSheet: View {
    @Binding var isShowing: Bool
    @Binding var manualBarcode: String
    @ObservedObject var viewModel: ScannerViewModel
    @EnvironmentObject var settings: UserSettings
    let scanStatusMessage: String
    let onScanStatusUpdate: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    BarcodeScannerView { code in
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        viewModel.handleBarcode(
                            code,
                            selectedAllergens: settings.selectedAllergens,
                            customAllergens: settings.activeCustomAllergenNames
                        )
                        isShowing = false
                    }
                    .frame(height: 350)

                    Text(scanStatusMessage)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }

                VStack(spacing: 12) {
                    TextField("Enter barcode number", text: $manualBarcode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                    Text("Barcodes are numeric and usually 12 digits long")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    HStack {
                        Spacer()
                        Button("Submit") {
                            guard !manualBarcode.isEmpty else { return }
                            viewModel.handleBarcode(
                                manualBarcode,
                                selectedAllergens: settings.selectedAllergens,
                                customAllergens: settings.activeCustomAllergenNames
                            )
                            manualBarcode = ""
                            isShowing = false
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                        Button(role: .cancel) {
                            isShowing = false
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        Spacer()
                    }
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding()
            .onAppear(perform: onScanStatusUpdate)
        }
    }
}
