//
//  CalculateAnalyticsUseCase+Overall.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateOverallAnalytics(from days: [DayData]) -> OverallAnalytics {
        let recordedDays = days.compactMap(RecordedDayData.init)
        let daysTracked = recordedDays.count

        var statusDist: [DayStatus: Int] = [.optimal: 0, .moderate: 0, .poor: 0, .incomplete: 0, .noData: 0]
        for day in recordedDays {
            statusDist[day.dayData.status, default: 0] += 1
        }

        let optimalDays = statusDist[.optimal] ?? 0
        let moderateDays = statusDist[.moderate] ?? 0
        let poorDays = statusDist[.poor] ?? 0
        let incompleteDays = statusDist[.incomplete] ?? 0

        let (currentOptimalStreak, longestOptimalStreak) = calculateStreaks(in: days) { $0.status == .optimal }

        let healthScore: Double = daysTracked > 0
            ? (Double(optimalDays) * 100.0 + Double(moderateDays) * 60.0
                + Double(poorDays) * 30.0 + Double(incompleteDays) * 10.0) / Double(daysTracked)
            : 0.0

        return OverallAnalytics(
            daysTracked: daysTracked,
            optimalDays: optimalDays,
            moderateDays: moderateDays,
            poorDays: poorDays,
            incompleteDays: incompleteDays,
            currentOptimalStreak: currentOptimalStreak,
            longestOptimalStreak: longestOptimalStreak,
            healthScore: healthScore,
            statusDistribution: statusDist
        )
    }
}
