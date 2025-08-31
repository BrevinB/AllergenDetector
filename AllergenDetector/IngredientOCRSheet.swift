import SwiftUI
import UIKit

/// Sheet that allows the user to capture an image of the ingredient list
/// and performs OCR-based analysis when submitted.
struct IngredientOCRSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ScannerViewModel
    @EnvironmentObject var settings: UserSettings
    let onFinished: () -> Void

    @State private var image: UIImage?
    @State private var showPicker = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else {
                    Text("No image selected")
                        .foregroundColor(.secondary)
                }

                Button("Take Photo") {
                    showPicker = true
                }
                .buttonStyle(.borderedProminent)

                if image != nil {
                    Button("Analyze") {
                        Task {
                            if let img = image {
                                await viewModel.handleOCR(
                                    img,
                                    selectedAllergens: settings.selectedAllergens,
                                    customAllergens: settings.activeCustomAllergenNames,
                                    isSubscriber: settings.isSubscriber
                                )
                                onFinished()
                                dismiss()
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Scan Ingredients")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showPicker) {
                ImagePicker(image: $image)
            }
        }
    }
}

