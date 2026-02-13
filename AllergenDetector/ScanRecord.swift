// ScanRecord.swift
// AllergenDetector
//
// Created by [Your Name] on [Date].

import Foundation

/// Indicates whether a scanned product is safe to consume.
enum SafetyStatus: String, Codable {
    case safe
    case unsafe
    case unknown
}

/// Represents a single scan event saved in history.
struct ScanRecord: Identifiable, Codable {
    let id: UUID
    let barcode: String
    let productName: String
    let dateScanned: Date
    let safety: SafetyStatus
    let profileId: UUID?  // Optional for backwards compatibility with existing data

    init(
        id: UUID = UUID(),
        barcode: String,
        productName: String,
        dateScanned: Date,
        safety: SafetyStatus,
        profileId: UUID? = nil
    ) {
        self.id = id
        self.barcode = barcode
        self.productName = productName
        self.dateScanned = dateScanned
        self.safety = safety
        self.profileId = profileId
    }
}
