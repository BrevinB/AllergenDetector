//
//  ExportService.swift
//  AllergenDetector
//
//  Service for exporting scan history in multiple formats
//

import Foundation
import UIKit
import PDFKit

/// Service to handle exporting scan history in various formats
class ExportService {
    static let shared = ExportService()

    private init() {}

    // MARK: - Main Export Method

    /// Exports scan history in the specified format
    func exportHistory(format: ExportFormat, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let url: URL?

            switch format {
            case .text:
                url = self.exportAsText()
            case .csv:
                url = self.exportAsCSV()
            case .pdf:
                url = self.exportAsPDF()
            }

            DispatchQueue.main.async {
                completion(url)
            }
        }
    }

    // MARK: - Text Export

    private func exportAsText() -> URL? {
        let records = HistoryService.shared.records
        let profile = ProfileManager.shared.activeProfile

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        var lines: [String] = []

        // Header
        if let profile = profile {
            lines.append("Scan History for \(profile.emoji) \(profile.name)")
            lines.append(String(repeating: "=", count: 50))
            lines.append("")
        }

        lines.append("Exported: \(formatter.string(from: Date()))")
        lines.append("Total Scans: \(records.count)")
        lines.append("")
        lines.append(String(repeating: "-", count: 50))
        lines.append("")

        // Records
        for record in records {
            let dateString = formatter.string(from: record.dateScanned)
            let safetyString: String

            switch record.safety {
            case .safe:
                safetyString = "✓ Safe"
            case .unsafe:
                safetyString = "✗ Unsafe"
            case .unknown:
                safetyString = "? Unknown"
            }

            lines.append("\(record.productName)")
            lines.append("  Barcode: \(record.barcode)")
            lines.append("  Date: \(dateString)")
            lines.append("  Status: \(safetyString)")
            lines.append("")
        }

        let text = lines.joined(separator: "\n")
        let filename = "ScanHistory_\(Date().timeIntervalSince1970).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to export as text: \(error)")
            return nil
        }
    }

    // MARK: - CSV Export

    private func exportAsCSV() -> URL? {
        let records = HistoryService.shared.records
        let profile = ProfileManager.shared.activeProfile

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var csvLines: [String] = []

        // Header row
        csvLines.append("Product Name,Barcode,Date Scanned,Safety Status,Profile")

        // Data rows
        for record in records {
            let productName = escapeCSV(record.productName)
            let barcode = escapeCSV(record.barcode)
            let date = dateFormatter.string(from: record.dateScanned)
            let safety = record.safety.rawValue.capitalized
            let profileName = escapeCSV(profile?.name ?? "Unknown")

            csvLines.append("\(productName),\(barcode),\(date),\(safety),\(profileName)")
        }

        let csvContent = csvLines.joined(separator: "\n")
        let filename = "ScanHistory_\(Date().timeIntervalSince1970).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try csvContent.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to export as CSV: \(error)")
            return nil
        }
    }

    /// Escapes CSV values by wrapping in quotes if needed
    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    // MARK: - PDF Export

    private func exportAsPDF() -> URL? {
        let records = HistoryService.shared.records
        let profile = ProfileManager.shared.activeProfile
        let insights = InsightsService.shared.insights

        // Create PDF context
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let filename = "ScanHistory_\(Date().timeIntervalSince1970).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        UIGraphicsBeginPDFContextToFile(url.path, pageSize, nil)
        guard UIGraphicsGetCurrentContext() != nil else {
            UIGraphicsEndPDFContext()
            return nil
        }

        var yPosition: CGFloat = 60

        // Page 1: Cover & Summary
        UIGraphicsBeginPDFPage()

        // Title
        yPosition = drawText(
            "Allergen Detector",
            at: CGPoint(x: 60, y: yPosition),
            font: .boldSystemFont(ofSize: 32),
            color: .black,
            maxWidth: pageSize.width - 120
        )

        yPosition += 10
        yPosition = drawText(
            "Scan History Report",
            at: CGPoint(x: 60, y: yPosition),
            font: .systemFont(ofSize: 24),
            color: .darkGray,
            maxWidth: pageSize.width - 120
        )

        yPosition += 40

        // Profile info
        if let profile = profile {
            yPosition = drawText(
                "\(profile.emoji) \(profile.name)",
                at: CGPoint(x: 60, y: yPosition),
                font: .boldSystemFont(ofSize: 20),
                color: .black,
                maxWidth: pageSize.width - 120
            )
            yPosition += 30
        }

        // Export date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        yPosition = drawText(
            "Exported: \(dateFormatter.string(from: Date()))",
            at: CGPoint(x: 60, y: yPosition),
            font: .systemFont(ofSize: 12),
            color: .gray,
            maxWidth: pageSize.width - 120
        )

        yPosition += 40

        // Summary statistics
        yPosition = drawText(
            "Summary Statistics",
            at: CGPoint(x: 60, y: yPosition),
            font: .boldSystemFont(ofSize: 18),
            color: .black,
            maxWidth: pageSize.width - 120
        )

        yPosition += 20

        let stats = [
            "Total Scans: \(insights.totalScans)",
            "Safe Products: \(insights.safeScans)",
            "Unsafe Products: \(insights.unsafeScans)",
            "Unknown Status: \(insights.unknownScans)",
            "Safety Rate: \(Int(insights.safetyRate * 100))%",
            "Current Streak: \(insights.currentStreak) day\(insights.currentStreak == 1 ? "" : "s")"
        ]

        for stat in stats {
            yPosition = drawText(
                stat,
                at: CGPoint(x: 80, y: yPosition),
                font: .systemFont(ofSize: 14),
                color: .black,
                maxWidth: pageSize.width - 140
            )
            yPosition += 5
        }

        // Scan history header
        yPosition += 40
        yPosition = drawText(
            "Scan History (\(records.count) scans)",
            at: CGPoint(x: 60, y: yPosition),
            font: .boldSystemFont(ofSize: 18),
            color: .black,
            maxWidth: pageSize.width - 120
        )

        yPosition += 25

        // Table header
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemGray5.cgColor)
        context?.fill(CGRect(x: 60, y: yPosition - 5, width: pageSize.width - 120, height: 25))

        yPosition = drawText(
            "Product",
            at: CGPoint(x: 70, y: yPosition),
            font: .boldSystemFont(ofSize: 12),
            color: .black,
            maxWidth: 250
        )

        _ = drawText(
            "Date",
            at: CGPoint(x: 330, y: yPosition - 15),
            font: .boldSystemFont(ofSize: 12),
            color: .black,
            maxWidth: 120
        )

        _ = drawText(
            "Status",
            at: CGPoint(x: 460, y: yPosition - 15),
            font: .boldSystemFont(ofSize: 12),
            color: .black,
            maxWidth: 80
        )

        yPosition += 10

        // Table rows
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        for (index, record) in records.enumerated() {
            // Check if we need a new page
            if yPosition > pageSize.height - 100 {
                UIGraphicsBeginPDFPage()
                yPosition = 60
            }

            // Alternate row background
            if index % 2 == 0 {
                context?.setFillColor(UIColor.systemGray6.cgColor)
                context?.fill(CGRect(x: 60, y: yPosition - 5, width: pageSize.width - 120, height: 22))
            }

            // Product name
            yPosition = drawText(
                record.productName,
                at: CGPoint(x: 70, y: yPosition),
                font: .systemFont(ofSize: 10),
                color: .black,
                maxWidth: 250
            )

            // Date
            _ = drawText(
                dateFormatter.string(from: record.dateScanned),
                at: CGPoint(x: 330, y: yPosition - 12),
                font: .systemFont(ofSize: 10),
                color: .darkGray,
                maxWidth: 120
            )

            // Status
            let statusColor: UIColor
            let statusText: String
            switch record.safety {
            case .safe:
                statusColor = .systemGreen
                statusText = "✓ Safe"
            case .unsafe:
                statusColor = .systemRed
                statusText = "✗ Unsafe"
            case .unknown:
                statusColor = .systemOrange
                statusText = "? Unknown"
            }

            _ = drawText(
                statusText,
                at: CGPoint(x: 460, y: yPosition - 12),
                font: .boldSystemFont(ofSize: 10),
                color: statusColor,
                maxWidth: 80
            )

            yPosition += 8
        }

        UIGraphicsEndPDFContext()
        return url
    }

    /// Helper to draw text in PDF and return new Y position
    @discardableResult
    private func drawText(
        _ text: String,
        at point: CGPoint,
        font: UIFont,
        color: UIColor,
        maxWidth: CGFloat
    ) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        attributedString.draw(in: CGRect(
            x: point.x,
            y: point.y,
            width: maxWidth,
            height: boundingRect.height
        ))

        return point.y + boundingRect.height
    }
}
