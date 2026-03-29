//
//  CalculateAnalyticsUseCase+Water.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateWaterAnalytics(from days: [DayData]) -> WaterAnalytics {
        let waterDays = days.compactMap { day -> (Date, Double)? in
            guard let water = day.water, water > 0 else { return nil }
            return (Calendar.current.startOfDay(for: day.date), water)
        }

        let waterIntakes = waterDays.map(\.1)
        let averageIntake = waterIntakes.isEmpty ? 0.0 : waterIntakes.reduce(0.0, +) / Double(waterIntakes.count)
        let maxIntake = waterIntakes.max() ?? 0.0
        let minIntake = waterIntakes.min() ?? 0.0
        let daysAboveOptimal = waterIntakes.filter { $0 >= 1.8 }.count
        let daysAboveModerate = waterIntakes.filter { $0 >= 1.0 }.count

        let consistencyScore: Double
        if waterIntakes.count > 1 {
            let variance = waterIntakes.reduce(0.0) { $0 + pow($1 - averageIntake, 2) } / Double(waterIntakes.count)
            consistencyScore = max(0, 100 - (sqrt(variance) * 50))
        } else {
            consistencyScore = 100.0
        }

        var dailyIntake: [Date: Double] = [:]
        for (date, intake) in waterDays {
            dailyIntake[date] = intake
        }

        return WaterAnalytics(
            averageIntake: averageIntake,
            maxIntake: maxIntake,
            minIntake: minIntake,
            daysAboveOptimal: daysAboveOptimal,
            daysAboveModerate: daysAboveModerate,
            consistencyScore: consistencyScore,
            dailyIntake: dailyIntake
        )
    }
}
