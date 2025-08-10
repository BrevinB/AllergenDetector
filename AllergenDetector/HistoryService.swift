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

    /// Creates a plain text representation of the history records.
    private func makeTextString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        var lines: [String] = []
        for record in records {
            let dateString = formatter.string(from: record.dateScanned)
            let safeString: String
            switch record.safety {
            case .safe:
                safeString = "Safe"
            case .unsafe:
                safeString = "Unsafe"
            case .unknown:
                safeString = "Unknown"
            }
            let line = "\(record.barcode) - \(record.productName) - \(dateString) - \(safeString)"
            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    /// Exports the current history records to a temporary text file and returns its URL.
    /// Runs on a background queue to avoid blocking the main thread.
    func exportText(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let text = self.makeTextString()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ScanHistory.txt")
            do {
                try text.write(to: url, atomically: true, encoding: .utf8)
                DispatchQueue.main.async { completion(url) }
            } catch {
                print("Failed to export history: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
}
