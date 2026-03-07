//
//  MealsBarChart.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Charts
import SwiftUI

/// Bar chart showing meal quantity distribution
struct MealsBarChart: View {
    let quantityDistribution: [Meal.Quantity: Int]

    private var chartData: [(quantity: Meal.Quantity, count: Int)] {
        quantityDistribution
            .filter { $0.value > 0 }
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { (quantity: $0.key, count: $0.value) }
    }

    var body: some View {
        Chart {
            ForEach(chartData, id: \.quantity) { item in
                BarMark(
                    x: .value(String(localized: "chart_size"), item.quantity.localizedName),
                    y: .value(String(localized: "chart_count"), item.count)
                )
                .foregroundStyle(.orange.gradient)
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                    }
                }
            }
        }
        .frame(height: 200)
    }
}

#Preview {
    MealsBarChart(quantityDistribution: [
        .verySmall: 3,
        .small: 8,
        .medium: 5,
        .large: 2
    ])
    .padding()
}
