// HistoryService.swift
// AllergenDetector
//
// Created by [Your Name] on [Date].

import Foundation
import Combine

/// A service to persist and publish scan history records.
class HistoryService: ObservableObject {
    static let shared = HistoryService()

    @Published var records: [ScanRecord] = []

    private let defaultsKey = "ScanHistory"

    private init() {
        load()
    }

    /// Adds a new scan record to history (at the front) and persists it.
    func addRecord(_ record: ScanRecord) {
        if let last = records.first,
           last.barcode == record.barcode,
           last.productName == record.productName,
           abs(record.dateScanned.timeIntervalSince(last.dateScanned)) < 5 {
            return
        }
        records.insert(record, at: 0)
        save()
    }

    /// Loads saved history from UserDefaults. If none exists, starts with an empty array.
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let saved = try? JSONDecoder().decode([ScanRecord].self, from: data) else {
            records = []
            return
        }
        records = saved
    }

    /// Encodes the current records array and writes it to UserDefaults.
    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    /// Creates a CSV string from the history records.
    private func makeCSVString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        var csvLines: [String] = ["Barcode,Product,Date,Safe"]
        for record in records {
            let dateString = formatter.string(from: record.dateScanned)
            let safeString = record.isSafe ? "Yes" : "No"
            let line = "\(record.barcode),\(record.productName),\(dateString),\(safeString)"
            csvLines.append(line)
        }

        return csvLines.joined(separator: "\n")
    }

    /// Exports the current history records to a temporary CSV file and returns its URL.
    /// The CSV contains columns: barcode, product name, date scanned, and safety status.
    /// Runs on a background queue to avoid blocking the main thread.
    func exportCSV(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let csvString = self.makeCSVString()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ScanHistory.csv")
            do {
                try csvString.write(to: url, atomically: true, encoding: .utf8)
                DispatchQueue.main.async { completion(url) }
            } catch {
                print("Failed to export CSV: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
}
