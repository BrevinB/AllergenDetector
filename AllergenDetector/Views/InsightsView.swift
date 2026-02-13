//
//  InsightsView.swift
//  AllergenDetector
//
//  Smart Insights Dashboard showing scan statistics and trends
//

import SwiftUI

struct InsightsView: View {
    @ObservedObject var insightsService = InsightsService.shared
    @ObservedObject var profileManager = ProfileManager.shared

    var insights: ScanInsights {
        insightsService.insights
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Header with Profile Info
                if let profile = profileManager.activeProfile {
                    VStack(spacing: 8) {
                        Text(profile.emoji)
                            .font(.system(size: 48))

                        Text("\(profile.name)'s Insights")
                            .font(.title2.bold())

                        if insights.totalScans > 0 {
                            Text("Based on \(insights.totalScans) scan\(insights.totalScans == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical)
                }

                if insights.totalScans == 0 {
                    // MARK: - Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No Insights Yet")
                            .font(.title2.bold())

                        Text("Start scanning products to see your personalized insights and statistics!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 60)
                } else {
                    // MARK: - Quick Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            icon: "chart.bar.fill",
                            title: "Total Scans",
                            value: "\(insights.totalScans)",
                            color: .blue
                        )

                        StatCard(
                            icon: "calendar",
                            title: "This Week",
                            value: "\(insights.scansThisWeek)",
                            color: .purple
                        )

                        StatCard(
                            icon: "checkmark.shield.fill",
                            title: "Safe Products",
                            value: "\(insights.safeScans)",
                            color: .green
                        )

                        StatCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Allergens Avoided",
                            value: "\(insights.allergenAvoided)",
                            color: .red
                        )
                    }

                    // MARK: - Safety Rate Progress
                    if insights.totalScans > 0 {
                        ProgressCard(
                            icon: "percent",
                            title: "Safety Rate",
                            percentage: insights.safetyRate,
                            subtitle: "\(insights.safeScans) out of \(insights.totalScans) products were safe for you",
                            color: insights.safetyRate >= 0.7 ? .green : insights.safetyRate >= 0.4 ? .orange : .red
                        )
                    }

                    // MARK: - Streaks
                    if insights.currentStreak > 0 || insights.longestStreak > 0 {
                        HStack(spacing: 12) {
                            if insights.currentStreak > 0 {
                                StatCard(
                                    icon: "flame.fill",
                                    title: "Current Streak",
                                    value: "\(insights.currentStreak)",
                                    subtitle: "day\(insights.currentStreak == 1 ? "" : "s")",
                                    color: .orange
                                )
                            }

                            if insights.longestStreak > 0 {
                                StatCard(
                                    icon: "trophy.fill",
                                    title: "Longest Streak",
                                    value: "\(insights.longestStreak)",
                                    subtitle: "day\(insights.longestStreak == 1 ? "" : "s")",
                                    color: .yellow
                                )
                            }
                        }
                    }

                    // MARK: - Weekly Activity Chart
                    if !insights.weeklyActivity.isEmpty {
                        WeeklyActivityChart(activity: insights.weeklyActivity)
                    }

                    // MARK: - Top Scanned Products
                    if !insights.mostScannedProducts.isEmpty {
                        TopItemsCard(
                            title: "Most Scanned Products",
                            icon: "star.fill",
                            items: insights.mostScannedProducts
                        )
                    }

                    // MARK: - Breakdown by Safety
                    if insights.totalScans > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.pie.fill")
                                    .foregroundColor(.accentColor)
                                    .imageScale(.large)

                                Text("Safety Breakdown")
                                    .font(.headline)

                                Spacer()
                            }

                            VStack(spacing: 8) {
                                SafetyBreakdownRow(
                                    icon: "checkmark.circle.fill",
                                    label: "Safe",
                                    count: insights.safeScans,
                                    total: insights.totalScans,
                                    color: .green
                                )

                                SafetyBreakdownRow(
                                    icon: "exclamationmark.triangle.fill",
                                    label: "Unsafe",
                                    count: insights.unsafeScans,
                                    total: insights.totalScans,
                                    color: .red
                                )

                                if insights.unknownScans > 0 {
                                    SafetyBreakdownRow(
                                        icon: "questionmark.circle.fill",
                                        label: "Unknown",
                                        count: insights.unknownScans,
                                        total: insights.totalScans,
                                        color: .orange
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Views

struct SafetyBreakdownRow: View {
    let icon: String
    let label: String
    let count: Int
    let total: Int
    let color: Color

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(count)")
                .font(.subheadline.bold())
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)

            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationView {
        InsightsView()
    }
}
