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
}
