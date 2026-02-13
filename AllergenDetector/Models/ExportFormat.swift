//
//  ExportFormat.swift
//  AllergenDetector
//
//  Export format options for scan history
//

import Foundation

/// Available export formats for scan history
enum ExportFormat: String, CaseIterable, Identifiable {
    case text = "Text (.txt)"
    case csv = "CSV (.csv)"
    case pdf = "PDF (.pdf)"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .text: return "txt"
        case .csv: return "csv"
        case .pdf: return "pdf"
        }
    }

    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .csv: return "tablecells"
        case .pdf: return "doc.richtext"
        }
    }

    var description: String {
        switch self {
        case .text: return "Simple text file"
        case .csv: return "Spreadsheet compatible"
        case .pdf: return "Professional report"
        }
    }
}
