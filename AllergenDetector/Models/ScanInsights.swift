//
//  ScanInsights.swift
//  AllergenDetector
//
//  Data models for scan statistics and insights
//

import Foundation

/// Statistics and insights calculated from scan history
struct ScanInsights {
    // MARK: - Overall Stats
    let totalScans: Int
    let safeScans: Int
    let unsafeScans: Int
    let unknownScans: Int

    // MARK: - Time-based Stats
    let scansThisWeek: Int
    let scansThisMonth: Int
    let scansToday: Int

    // MARK: - Safety Metrics
    var safetyRate: Double {
        guard totalScans > 0 else { return 0 }
        return Double(safeScans) / Double(totalScans)
    }

    var unsafeRate: Double {
        guard totalScans > 0 else { return 0 }
        return Double(unsafeScans) / Double(totalScans)
    }

    // MARK: - Product Analysis
    let mostScannedProducts: [ProductFrequency]
    let recentlyScanned: [ScanRecord]

    // MARK: - Allergen Avoidance
    let allergenAvoided: Int  // Count of unsafe products avoided

    // MARK: - Streaks
    let currentStreak: Int  // Days with at least one scan
    let longestStreak: Int

    // MARK: - Weekly Chart Data
    let weeklyActivity: [DayActivity]

    /// Empty state for when there's no scan data
    static var empty: ScanInsights {
        return ScanInsights(
            totalScans: 0,
            safeScans: 0,
            unsafeScans: 0,
            unknownScans: 0,
            scansThisWeek: 0,
            scansThisMonth: 0,
            scansToday: 0,
            mostScannedProducts: [],
            recentlyScanned: [],
            allergenAvoided: 0,
            currentStreak: 0,
            longestStreak: 0,
            weeklyActivity: []
        )
    }
}

/// Frequency data for a specific product
struct ProductFrequency: Identifiable {
    let id = UUID()
    let productName: String
    let barcode: String
    let scanCount: Int
    let lastScanned: Date
    let safetyStatus: SafetyStatus
}

/// Daily activity data for charts
struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let scanCount: Int
    let dayName: String  // "Mon", "Tue", etc.

    init(date: Date, scanCount: Int) {
        self.date = date
        self.scanCount = scanCount

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        self.dayName = formatter.string(from: date)
    }
}

/// Time period for filtering insights
enum InsightsTimePeriod {
    case week
    case month
    case allTime

    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .allTime: return "All Time"
        }
    }
}
