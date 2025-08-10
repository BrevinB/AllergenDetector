// HistoryView.swift
// AllergenDetector
//
// Created by Brevin Blalock on 6/xx/25.

import SwiftUI

struct HistoryView: View {
    @ObservedObject private var history = HistoryService.shared
    @State private var editMode: EditMode = .inactive
    @State private var exportURL: URL?
    @State private var showingShare = false
    @State private var isExporting = false

    // DateFormatter for displaying scan timestamps
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        List {
            // When in edit mode, show a “Clear All History” button at the top
            if editMode == .active {
                Button("Clear All History") {
                    history.records.removeAll()
                }
                .foregroundColor(.red)
            }

            if history.records.isEmpty {
                Text("No scans yet.")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(history.records) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.productName)
                                .font(.headline)
                            Text(dateFormatter.string(from: record.dateScanned))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: {
                            switch record.safety {
                            case .safe: return "checkmark.seal.fill"
                            case .unsafe: return "xmark.shield.fill"
                            case .unknown: return "questionmark.diamond.fill"
                            }
                        }())
                        .foregroundColor({
                            switch record.safety {
                            case .safe: return .green
                            case .unsafe: return .red
                            case .unknown: return .yellow
                            }
                        }())
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indices in
                    history.records.remove(atOffsets: indices)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Scan History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    isExporting = true
                    history.exportText { url in
                        exportURL = url
                        showingShare = url != nil
                        isExporting = false
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showingShare, onDismiss: { exportURL = nil }) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Exporting…")
                        .padding(20)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        HistoryView()
    }
}

