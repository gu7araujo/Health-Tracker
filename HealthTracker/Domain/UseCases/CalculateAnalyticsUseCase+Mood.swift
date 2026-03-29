//
//  CalculateAnalyticsUseCase+Mood.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateMoodAnalytics(from days: [DayData], period _: AnalyticsPeriod) -> MoodAnalytics {
        let moodDays = days.compactMap { day -> (Date, Mood)? in
            guard let mood = day.mood else { return nil }
            return (Calendar.current.startOfDay(for: day.date), mood)
        }

        var distribution: [Mood: Int] = [:]
        for mood in Mood.allCases {
            distribution[mood] = moodDays.filter { $0.1 == mood }.count
        }

        let goodDaysCount = distribution[.good] ?? 0
        let goodDaysPercentage = moodDays.isEmpty ? 0.0 : (Double(goodDaysCount) / Double(moodDays.count)) * 100.0

        var dailyMood: [Date: Mood] = [:]
        for (date, mood) in moodDays {
            dailyMood[date] = mood
        }

        let (bestWeek, worstWeek) = calculateBestWorstWeeks(from: days)

        return MoodAnalytics(
            distribution: distribution,
            goodDaysPercentage: goodDaysPercentage,
            dailyMood: dailyMood,
            bestWeek: bestWeek,
            worstWeek: worstWeek
        )
    }

    private func calculateBestWorstWeeks(from days: [DayData]) -> (best: Date?, worst: Date?) {
        let calendar = Calendar.current
        var weeklyMoods: [Date: [Mood]] = [:]
        for day in days {
            guard let mood = day.mood,
                  let weekStart = calendar.dateInterval(of: .weekOfYear, for: day.date)?.start else { continue }
            weeklyMoods[calendar.startOfDay(for: weekStart), default: []].append(mood)
        }
        guard !weeklyMoods.isEmpty else { return (nil, nil) }
        let weekScores = weeklyMoods.map { week, moods in
            (week: week, score: Double(moods.filter { $0 == .good }.count) / Double(moods.count))
        }
        return (weekScores.max(by: { $0.score < $1.score })?.week,
                weekScores.min(by: { $0.score < $1.score })?.week)
    }
}
