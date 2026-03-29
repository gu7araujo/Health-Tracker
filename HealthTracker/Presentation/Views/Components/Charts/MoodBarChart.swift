//
//  MoodBarChart.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Charts
import SwiftUI

/// Bar chart showing mood distribution
struct MoodBarChart: View {
    let distribution: [Mood: Int]

    private var chartData: [MoodChartItem] {
        distribution
            .filter { $0.value > 0 }
            .map { mood, count in
                let color: Color = switch mood {
                case .good: .green
                case .neutral: .orange
                case .sad: .red
                }
                return MoodChartItem(mood: mood, count: count, color: color)
            }
            .sorted { $0.mood.rawValue < $1.mood.rawValue }
    }

    var body: some View {
        Chart {
            ForEach(chartData, id: \.mood) { item in
                BarMark(
                    x: .value(String(localized: "chart_mood"), "\(item.mood.emoji) \(item.mood.localizedName)"),
                    y: .value(String(localized: "chart_days"), item.count)
                )
                .foregroundStyle(item.color.gradient)
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let days = value.as(Int.self) {
                        Text("\(days)")
                    }
                }
            }
        }
        .frame(height: 200)
    }
}

private struct MoodChartItem {
    let mood: Mood
    let count: Int
    let color: Color
}

#Preview {
    MoodBarChart(distribution: [
        .good: 5,
        .neutral: 3,
        .sad: 2
    ])
    .padding()
}
