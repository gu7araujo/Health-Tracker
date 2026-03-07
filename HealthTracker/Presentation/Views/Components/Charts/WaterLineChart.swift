//
//  WaterLineChart.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Charts
import SwiftUI

/// Line chart showing daily water intake with goal threshold lines
struct WaterLineChart: View {
    let dailyIntake: [Date: Double]
    let dateRange: ClosedRange<Date>

    private var sortedData: [(date: Date, intake: Double)] {
        dailyIntake.sorted { $0.key < $1.key }
            .map { (date: $0.key, intake: $0.value) }
    }

    var body: some View {
        Chart {
            // Water intake line and area
            ForEach(sortedData, id: \.date) { entry in
                LineMark(
                    x: .value(String(localized: "chart_date"), entry.date, unit: .day),
                    y: .value(String(localized: "chart_liters"), entry.intake)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value(String(localized: "chart_date"), entry.date, unit: .day),
                    y: .value(String(localized: "chart_liters"), entry.intake)
                )
                .foregroundStyle(.blue.opacity(0.2))
                .interpolationMethod(.catmullRom)
            }

            // Optimal threshold line (1.8L)
            RuleMark(y: .value(String(localized: "chart_optimal"), 1.8))
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(String(localized: "chart_optimal"))
                        .font(.caption2)
                        .foregroundStyle(.green)
                }

            // Moderate threshold line (1.0L)
            RuleMark(y: .value(String(localized: "chart_moderate"), 1.0))
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(String(localized: "chart_moderate"))
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
        }
        .chartYAxis {
            AxisMarks(values: [0, 1.0, 1.8, 3.0, 5.0])
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: sortedData.count > 7 ? 7 : 1)) { _ in
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
        .frame(height: 200)
    }
}

#Preview {
    let sampleData: [Date: Double] = [
        Calendar.current.date(byAdding: .day, value: -6, to: Date())!: 1.5,
        Calendar.current.date(byAdding: .day, value: -5, to: Date())!: 2.0,
        Calendar.current.date(byAdding: .day, value: -4, to: Date())!: 1.2,
        Calendar.current.date(byAdding: .day, value: -3, to: Date())!: 2.5,
        Calendar.current.date(byAdding: .day, value: -2, to: Date())!: 1.8,
        Calendar.current.date(byAdding: .day, value: -1, to: Date())!: 2.2,
        Date(): 1.9
    ]

    let range = Calendar.current.date(byAdding: .day, value: -6, to: Date())! ... Date()

    WaterLineChart(dailyIntake: sampleData, dateRange: range)
        .padding()
}
