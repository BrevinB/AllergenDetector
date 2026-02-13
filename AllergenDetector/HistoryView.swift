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
    @State private var showingExportOptions = false
    @State private var selectedFormat: ExportFormat = .csv
    @State private var filter = SearchFilter()
    @State private var showingFilters = false

    // DateFormatter for displaying scan timestamps
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    // Filtered records based on search and filter criteria
    private var filteredRecords: [ScanRecord] {
        filter.apply(to: history.records)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search products or barcodes", text: $filter.searchText)
                        .textFieldStyle(PlainTextFieldStyle())

                    if !filter.searchText.isEmpty {
                        Button(action: {
                            filter.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                Button(action: {
                    showingFilters = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundColor(filter.hasActiveFilters ? .accentColor : .primary)

                        if filter.activeFilterCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("\(filter.activeFilterCount)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                )
                                .offset(x: 6, y: -6)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Active filter chips
            if filter.hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(filter.safetyStatuses.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { status in
                            if filter.safetyStatuses.count < 3 {
                                FilterChip(
                                    text: status.rawValue.capitalized,
                                    icon: statusIcon(for: status),
                                    color: statusColor(for: status)
                                )
                            }
                        }

                        if filter.dateRange != .allTime {
                            FilterChip(
                                text: filter.dateRange.rawValue,
                                icon: "calendar",
                                color: .blue,
                                onRemove: {
                                    filter.dateRange = .allTime
                                }
                            )
                        }

                        Button(action: {
                            filter.reset()
                        }) {
                            Text("Clear All")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }

            Divider()

            // Results list
            List {
                // When in edit mode, show a "Clear All History" button at the top
                if editMode == .active {
                    Button("Clear All History") {
                        history.records.removeAll()
                    }
                    .foregroundColor(.red)
                }

                if filteredRecords.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: filter.hasActiveFilters ? "magnifyingglass" : "clock")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text(filter.hasActiveFilters ? "No results found" : "No scans yet")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        if filter.hasActiveFilters {
                            Text("Try adjusting your filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(filteredRecords) { record in
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
                        // Map filtered indices to original indices
                        let recordsToDelete = indices.map { filteredRecords[$0].id }
                        history.records.removeAll { record in
                            recordsToDelete.contains(record.id)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle(filteredRecords.isEmpty ? "Scan History" : "History (\(filteredRecords.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingExportOptions = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(history.records.isEmpty)
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showingFilters) {
            FilterSheet(filter: $filter)
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportFormatPicker(
                selectedFormat: $selectedFormat,
                onExport: { format in
                    showingExportOptions = false
                    performExport(format: format)
                }
            )
        }
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

    private func performExport(format: ExportFormat) {
        isExporting = true
        ExportService.shared.exportHistory(format: format) { url in
            exportURL = url
            showingShare = url != nil
            isExporting = false
        }
    }

    private func statusIcon(for safety: SafetyStatus) -> String {
        switch safety {
        case .safe: return "checkmark.seal.fill"
        case .unsafe: return "xmark.shield.fill"
        case .unknown: return "questionmark.diamond.fill"
        }
    }

    private func statusColor(for safety: SafetyStatus) -> Color {
        switch safety {
        case .safe: return .green
        case .unsafe: return .red
        case .unknown: return .orange
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let text: String
    let icon: String
    let color: Color
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(text)
                .font(.caption.bold())

            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var filter: SearchFilter
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                // Safety Status Section
                Section(header: Text("Safety Status")) {
                    ForEach([SafetyStatus.safe, .unsafe, .unknown], id: \.self) { status in
                        Toggle(isOn: Binding(
                            get: { filter.safetyStatuses.contains(status) },
                            set: { isOn in
                                if isOn {
                                    filter.safetyStatuses.insert(status)
                                } else {
                                    filter.safetyStatuses.remove(status)
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: iconFor(status))
                                    .foregroundColor(colorFor(status))
                                Text(status.rawValue.capitalized)
                            }
                        }
                    }
                }

                // Date Range Section
                Section(header: Text("Date Range")) {
                    Picker("Date Range", selection: $filter.dateRange) {
                        ForEach(DateRange.allCases) { range in
                            HStack {
                                Image(systemName: range.icon)
                                Text(range.rawValue)
                            }
                            .tag(range)
                        }
                    }
                    .pickerStyle(InlinePickerStyle())
                }

                // Sort Order Section
                Section(header: Text("Sort By")) {
                    Picker("Sort Order", selection: $filter.sortOrder) {
                        ForEach(SortOrder.allCases) { order in
                            HStack {
                                Image(systemName: order.icon)
                                Text(order.rawValue)
                            }
                            .tag(order)
                        }
                    }
                    .pickerStyle(InlinePickerStyle())
                }

                // Reset Section
                if filter.hasActiveFilters {
                    Section {
                        Button(action: {
                            filter.reset()
                        }) {
                            HStack {
                                Spacer()
                                Label("Reset All Filters", systemImage: "arrow.counterclockwise")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func iconFor(_ status: SafetyStatus) -> String {
        switch status {
        case .safe: return "checkmark.seal.fill"
        case .unsafe: return "xmark.shield.fill"
        case .unknown: return "questionmark.diamond.fill"
        }
    }

    private func colorFor(_ status: SafetyStatus) -> Color {
        switch status {
        case .safe: return .green
        case .unsafe: return .red
        case .unknown: return .orange
        }
    }
}

// MARK: - Export Format Picker

struct ExportFormatPicker: View {
    @Binding var selectedFormat: ExportFormat
    let onExport: (ExportFormat) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Choose Export Format")) {
                    ForEach(ExportFormat.allCases) { format in
                        Button(action: {
                            selectedFormat = format
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: format.icon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor.opacity(0.1))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(format.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Section {
                    Button(action: {
                        onExport(selectedFormat)
                    }) {
                        HStack {
                            Spacer()
                            Label("Export as \(selectedFormat.rawValue)", systemImage: "square.and.arrow.up")
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
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

