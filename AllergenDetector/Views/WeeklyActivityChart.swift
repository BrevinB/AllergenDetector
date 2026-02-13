//
//  WeeklyActivityChart.swift
//  AllergenDetector
//
//  Simple bar chart showing weekly scan activity
//

import SwiftUI

struct WeeklyActivityChart: View {
    let activity: [DayActivity]

    private var maxScans: Int {
        activity.map { $0.scanCount }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(.accentColor)
                    .imageScale(.large)

                Text("Weekly Activity")
                    .font(.headline)

                Spacer()

                Text("Last 7 Days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(activity) { day in
                    VStack(spacing: 4) {
                        // Bar
                        VStack {
                            Spacer(minLength: 0)

                            if day.scanCount > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: barHeight(for: day.scanCount))
                                    .overlay(
                                        Text("\(day.scanCount)")
                                            .font(.caption2.bold())
                                            .foregroundColor(.white)
                                            .opacity(day.scanCount > 0 ? 1 : 0)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 4)
                            }
                        }
                        .frame(height: 100)

                        // Day label
                        Text(day.dayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    private func barHeight(for count: Int) -> CGFloat {
        guard maxScans > 0 else { return 4 }
        let ratio = CGFloat(count) / CGFloat(maxScans)
        return max(20, ratio * 90)  // Min 20, max 90
    }
}

#Preview {
    let sampleActivity = [
        DayActivity(date: Date().addingTimeInterval(-6 * 24 * 3600), scanCount: 3),
        DayActivity(date: Date().addingTimeInterval(-5 * 24 * 3600), scanCount: 5),
        DayActivity(date: Date().addingTimeInterval(-4 * 24 * 3600), scanCount: 2),
        DayActivity(date: Date().addingTimeInterval(-3 * 24 * 3600), scanCount: 0),
        DayActivity(date: Date().addingTimeInterval(-2 * 24 * 3600), scanCount: 7),
        DayActivity(date: Date().addingTimeInterval(-1 * 24 * 3600), scanCount: 4),
        DayActivity(date: Date(), scanCount: 6)
    ]

    return WeeklyActivityChart(activity: sampleActivity)
        .padding()
}
