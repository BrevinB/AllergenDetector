// ScanRecord.swift
// AllergenDetector
//
// Created by [Your Name] on [Date].

import Foundation

/// Represents a single scan event saved in history.
struct ScanRecord: Identifiable, Codable {
    let id: UUID
    let barcode: String
    let productName: String
    let dateScanned: Date
    let isSafe: Bool
}
