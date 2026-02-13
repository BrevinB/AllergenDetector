//
//  InsightsService.swift
//  AllergenDetector
//
//  Service to calculate scan statistics and insights
//

import Foundation
import Combine

/// Calculates and provides insights from scan history
class InsightsService: ObservableObject {
    static let shared = InsightsService()

    @Published var insights: ScanInsights = .empty
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Recalculate insights when history changes
        HistoryService.shared.$records
            .sink { [weak self] _ in
                self?.calculateInsights()
            }
            .store(in: &cancellables)

        // Initial calculation
        calculateInsights()
    }

    /// Calculates all insights from the current scan history
    func calculateInsights() {
        let records = HistoryService.shared.records
        guard !records.isEmpty else {
            insights = .empty
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // MARK: - Overall Stats
        let totalScans = records.count
        let safeScans = records.filter { $0.safety == .safe }.count
        let unsafeScans = records.filter { $0.safety == .unsafe }.count
        let unknownScans = records.filter { $0.safety == .unknown }.count

        // MARK: - Time-based Stats
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let startOfMonth = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        let scansToday = records.filter { $0.dateScanned >= startOfToday }.count
        let scansThisWeek = records.filter { $0.dateScanned >= startOfWeek }.count
        let scansThisMonth = records.filter { $0.dateScanned >= startOfMonth }.count

        // MARK: - Most Scanned Products
        var productCounts: [String: (count: Int, record: ScanRecord)] = [:]
        for record in records {
            if let existing = productCounts[record.barcode] {
                productCounts[record.barcode] = (existing.count + 1, record)
            } else {
                productCounts[record.barcode] = (1, record)
            }
        }

        let mostScannedProducts = productCounts
            .map { barcode, data in
                ProductFrequency(
                    productName: data.record.productName,
                    barcode: barcode,
                    scanCount: data.count,
                    lastScanned: data.record.dateScanned,
                    safetyStatus: data.record.safety
                )
            }
            .sorted { $0.scanCount > $1.scanCount }
            .prefix(5)
            .map { $0 }

        // MARK: - Recent Scans
        let recentlyScanned = Array(records.prefix(5))

        // MARK: - Allergen Avoidance Count
        let allergenAvoided = unsafeScans

        // MARK: - Streaks
        let streaks = calculateStreaks(from: records)

        // MARK: - Weekly Activity
        let weeklyActivity = calculateWeeklyActivity(from: records)

        // Build the insights object
        insights = ScanInsights(
            totalScans: totalScans,
            safeScans: safeScans,
            unsafeScans: unsafeScans,
            unknownScans: unknownScans,
            scansThisWeek: scansThisWeek,
            scansThisMonth: scansThisMonth,
            scansToday: scansToday,
            mostScannedProducts: mostScannedProducts,
            recentlyScanned: recentlyScanned,
            allergenAvoided: allergenAvoided,
            currentStreak: streaks.current,
            longestStreak: streaks.longest,
            weeklyActivity: weeklyActivity
        )
    }

    // MARK: - Helper Methods

    /// Calculates scanning streaks (consecutive days with scans)
    private func calculateStreaks(from records: [ScanRecord]) -> (current: Int, longest: Int) {
        guard !records.isEmpty else { return (0, 0) }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique days with scans
        let scanDays = Set(records.map { calendar.startOfDay(for: $0.dateScanned) })
            .sorted(by: >)

        // Calculate current streak
        var currentStreak = 0
        var checkDate = today

        while scanDays.contains(checkDate) {
            currentStreak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 0
        var previousDate: Date?

        for day in scanDays.sorted() {
            if let prev = previousDate {
                let daysBetween = calendar.dateComponents([.day], from: prev, to: day).day ?? 0
                if daysBetween == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            previousDate = day
        }
        longestStreak = max(longestStreak, tempStreak)

        return (currentStreak, longestStreak)
    }

    /// Calculates daily scan counts for the last 7 days
    private func calculateWeeklyActivity(from records: [ScanRecord]) -> [DayActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var activities: [DayActivity] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date

            let scansForDay = records.filter {
                $0.dateScanned >= date && $0.dateScanned < endOfDay
            }.count

            activities.append(DayActivity(date: date, scanCount: scansForDay))
        }

        return activities
    }

    /// Gets insights for a specific time period
    func getInsights(for period: InsightsTimePeriod) -> ScanInsights {
        // For now, we always return current insights
        // This could be extended to filter by period in the future
        return insights
    }
}
