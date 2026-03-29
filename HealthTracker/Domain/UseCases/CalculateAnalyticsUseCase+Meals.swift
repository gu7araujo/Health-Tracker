//
//  CalculateAnalyticsUseCase+Meals.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateMealAnalytics(from days: [DayData], period _: AnalyticsPeriod) -> MealAnalytics {
        let allMeals = days.flatMap(\.meals)

        let totalMeals = allMeals.count

        let averageSatisfaction: Double
        if !allMeals.isEmpty {
            let totalSatisfaction = allMeals.reduce(0.0) { sum, meal in
                let percentage = switch meal.satisfaction {
                case .thirty: 30.0
                case .fifty: 50.0
                case .eighty: 80.0
                case .hundred: 100.0
                }
                return sum + percentage
            }
            averageSatisfaction = totalSatisfaction / Double(allMeals.count)
        } else {
            averageSatisfaction = 0.0
        }

        let optimalDaysCount = days.filter { day in
            !day.meals.isEmpty && day.meals.allSatisfy { meal in
                (meal.quantity == .small || meal.quantity == .verySmall) && meal.satisfaction == .fifty
            }
        }.count

        return MealAnalytics(
            totalMeals: totalMeals,
            averageSatisfaction: averageSatisfaction,
            quantityDistribution: buildQuantityDistribution(from: allMeals),
            satisfactionDistribution: buildSatisfactionDistribution(from: allMeals),
            optimalDaysCount: optimalDaysCount,
            dailyCounts: buildDailyCounts(from: days),
            satisfactionTrend: buildSatisfactionTrend(from: days)
        )
    }

    private func buildQuantityDistribution(from meals: [Meal]) -> [Meal.Quantity: Int] {
        var dist: [Meal.Quantity: Int] = [:]
        for quantity in Meal.Quantity.allCases {
            dist[quantity] = meals.filter { $0.quantity == quantity }.count
        }
        return dist
    }

    private func buildSatisfactionDistribution(from meals: [Meal]) -> [Meal.Satisfaction: Int] {
        var dist: [Meal.Satisfaction: Int] = [:]
        for satisfaction in Meal.Satisfaction.allCases {
            dist[satisfaction] = meals.filter { $0.satisfaction == satisfaction }.count
        }
        return dist
    }

    private func buildDailyCounts(from days: [DayData]) -> [Date: Int] {
        var counts: [Date: Int] = [:]
        for day in days {
            let normalizedDate = Calendar.current.startOfDay(for: day.date)
            counts[normalizedDate] = day.meals.count
        }
        return counts
    }

    private func buildSatisfactionTrend(from days: [DayData]) -> [Date: [Meal.Satisfaction: Int]] {
        var trend: [Date: [Meal.Satisfaction: Int]] = [:]
        for day in days where !day.meals.isEmpty {
            let normalizedDate = Calendar.current.startOfDay(for: day.date)
            var dist: [Meal.Satisfaction: Int] = [:]
            for satisfaction in Meal.Satisfaction.allCases {
                dist[satisfaction] = day.meals.filter { $0.satisfaction == satisfaction }.count
            }
            trend[normalizedDate] = dist
        }
        return trend
    }
}
