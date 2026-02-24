//
//  OverallHealthRingChart.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Charts
import SwiftUI

/// Ring/donut chart showing overall health status distribution
struct OverallHealthRingChart: View {
    let statusDistribution: [DayStatus: Int]

    private var chartData: [(status: DayStatus, count: Int, color: Color)] {
        statusDistribution
            .filter { $0.value > 0 }
            .map { status, count in
                let color: Color = switch status {
                case .optimal: .green
                case .moderate: .yellow
                case .poor: .red
                case .incomplete: .gray
                case .noData: .clear
                }
                return (status: status, count: count, color: color)
            }
            .sorted { $0.count > $1.count }
    }

    private var totalDays: Int {
        chartData.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        VStack(spacing: 8) {
            if !chartData.isEmpty {
                Chart(chartData, id: \.status) { item in
                    SectorMark(
                        angle: .value("Contagem", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .overlay {
                    VStack(spacing: 4) {
                        Text("\(totalDays)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("dias")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(chartData, id: \.status) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text(statusLabel(for: item.status))
                                .font(.caption)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            } else {
                Text("Sem dados suficientes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
            }
        }
    }

    private func statusLabel(for status: DayStatus) -> String {
        switch status {
        case .optimal: "Ótimo"
        case .moderate: "Moderado"
        case .poor: "Pobre"
        case .incomplete: "Incompleto"
        case .noData: "Sem dados"
        }
    }
}

#Preview {
    OverallHealthRingChart(statusDistribution: [
        .optimal: 5,
        .moderate: 3,
        .poor: 1,
        .incomplete: 2
    ])
    .padding()
}
