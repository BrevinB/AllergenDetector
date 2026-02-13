//
//  SearchFilter.swift
//  AllergenDetector
//
//  Models for searching and filtering scan history
//

import Foundation

/// Filter options for scan history
struct SearchFilter {
    var searchText: String = ""
    var safetyStatuses: Set<SafetyStatus> = [.safe, .unsafe, .unknown]
    var dateRange: DateRange = .allTime
    var sortOrder: SortOrder = .newestFirst

    /// Checks if any filters are active (non-default)
    var hasActiveFilters: Bool {
        return !searchText.isEmpty ||
               safetyStatuses.count != 3 ||
               dateRange != .allTime
    }

    /// Returns the count of active filters
    var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if safetyStatuses.count != 3 { count += 1 }
        if dateRange != .allTime { count += 1 }
        return count
    }

    /// Resets all filters to default
    mutating func reset() {
        searchText = ""
        safetyStatuses = [.safe, .unsafe, .unknown]
        dateRange = .allTime
        sortOrder = .newestFirst
    }

    /// Filters a list of scan records based on current filter settings
    func apply(to records: [ScanRecord]) -> [ScanRecord] {
        var filtered = records

        // Text search
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            filtered = filtered.filter { record in
                record.productName.lowercased().contains(lowercased) ||
                record.barcode.contains(searchText)
            }
        }

        // Safety status filter
        filtered = filtered.filter { record in
            safetyStatuses.contains(record.safety)
        }

        // Date range filter
        filtered = filtered.filter { record in
            dateRange.contains(record.dateScanned)
        }

        // Sort
        switch sortOrder {
        case .newestFirst:
            filtered.sort { $0.dateScanned > $1.dateScanned }
        case .oldestFirst:
            filtered.sort { $0.dateScanned < $1.dateScanned }
        case .nameAZ:
            filtered.sort { $0.productName.lowercased() < $1.productName.lowercased() }
        case .nameZA:
            filtered.sort { $0.productName.lowercased() > $1.productName.lowercased() }
        }

        return filtered
    }
}

/// Date range options for filtering
enum DateRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case yesterday = "Yesterday"
    case lastWeek = "Last 7 Days"
    case lastMonth = "Last 30 Days"
    case lastYear = "Last Year"
    case allTime = "All Time"

    var id: String { rawValue }

    /// Checks if a given date falls within this range
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            return calendar.isDateInToday(date)

        case .yesterday:
            return calendar.isDateInYesterday(date)

        case .lastWeek:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
            return date >= weekAgo

        case .lastMonth:
            guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return false }
            return date >= monthAgo

        case .lastYear:
            guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) else { return false }
            return date >= yearAgo

        case .allTime:
            return true
        }
    }

    var icon: String {
        switch self {
        case .today: return "calendar"
        case .yesterday: return "calendar.badge.clock"
        case .lastWeek: return "calendar.badge.plus"
        case .lastMonth: return "calendar"
        case .lastYear: return "calendar.badge.exclamationmark"
        case .allTime: return "infinity"
        }
    }
}

/// Sort order options
enum SortOrder: String, CaseIterable, Identifiable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case nameAZ = "Name (A-Z)"
    case nameZA = "Name (Z-A)"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .newestFirst: return "arrow.down"
        case .oldestFirst: return "arrow.up"
        case .nameAZ: return "textformat.abc"
        case .nameZA: return "textformat.abc"
        }
    }
}
