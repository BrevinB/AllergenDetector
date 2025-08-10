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
}
