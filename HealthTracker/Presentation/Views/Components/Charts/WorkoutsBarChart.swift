//
//  WorkoutsBarChart.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Charts
import SwiftUI

/// Bar chart showing weekly workout volume
struct WorkoutsBarChart: View {
    let weeklyVolume: [Date: Int]

    private var sortedData: [(weekStart: Date, minutes: Int)] {
        weeklyVolume.sorted { $0.key < $1.key }
            .map { (weekStart: $0.key, minutes: $0.value) }
    }

    var body: some View {
        Chart {
            ForEach(sortedData, id: \.weekStart) { entry in
                BarMark(
                    x: .value(String(localized: "chart_week"), entry.weekStart, unit: .weekOfYear),
                    y: .value(String(localized: "chart_minutes"), entry.minutes)
                )
                .foregroundStyle(.purple.gradient)
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let minutes = value.as(Int.self) {
                        Text(String(format: String(localized: "duration_format_minutes"), minutes))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
        .frame(height: 200)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()

    let sampleData: [Date: Int] = [
        calendar.date(byAdding: .weekOfYear, value: -3, to: today)!: 120,
        calendar.date(byAdding: .weekOfYear, value: -2, to: today)!: 180,
        calendar.date(byAdding: .weekOfYear, value: -1, to: today)!: 90,
        today: 150
    ]

    WorkoutsBarChart(weeklyVolume: sampleData)
        .padding()
}
