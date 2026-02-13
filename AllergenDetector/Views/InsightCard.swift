//
//  InsightCard.swift
//  AllergenDetector
//
//  Reusable card components for displaying insights
//

import SwiftUI

/// A stat card showing a single metric with icon and value
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let color: Color

    init(icon: String, title: String, value: String, subtitle: String? = nil, color: Color = .brand) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .imageScale(.large)
                    .frame(width: 32, height: 32)

                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .themedCard()
    }
}

/// A progress card showing percentage with a progress bar
struct ProgressCard: View {
    let icon: String
    let title: String
    let percentage: Double
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .imageScale(.large)

                Spacer()

                Text("\(Int(percentage * 100))%")
                    .font(.title2.bold())
                    .foregroundColor(color)
            }

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

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

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .themedCard()
    }
}

/// A list card showing top items
struct TopItemsCard: View {
    let title: String
    let icon: String
    let items: [ProductFrequency]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brand)
                    .imageScale(.large)

                Text(title)
                    .font(.headline)

                Spacer()
            }
            .padding(.bottom, 4)

            if items.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, product in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.productName)
                                .font(.subheadline)
                                .lineLimit(1)

                            Text("\(product.scanCount) scan\(product.scanCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        SafetyBadge(status: product.safetyStatus)
                    }
                    .padding(.vertical, 4)

                    if index < items.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .themedCard()
    }
}

/// Small badge showing safety status
struct SafetyBadge: View {
    let status: SafetyStatus

    var body: some View {
        Image(systemName: status.themeIcon)
            .foregroundColor(status.themeColor)
            .imageScale(.medium)
    }
}

#Preview("Stat Card") {
    StatCard(
        icon: "chart.bar.fill",
        title: "Total Scans",
        value: "47",
        subtitle: "This month",
        color: .brand
    )
    .padding()
}

#Preview("Progress Card") {
    ProgressCard(
        icon: "checkmark.shield.fill",
        title: "Safety Rate",
        percentage: 0.73,
        subtitle: "73% of products were safe",
        color: .safeGreen
    )
    .padding()
}
