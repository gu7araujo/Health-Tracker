//
//  CalculateAnalyticsUseCase+Workout.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateWorkoutAnalytics(from days: [DayData]) -> WorkoutAnalytics {
        let allWorkouts = days.flatMap(\.workouts)
        let totalWorkouts = allWorkouts.count
        let totalMinutes = allWorkouts.reduce(0) { $0 + $1.duration.minutes }
        let averageDuration = allWorkouts.isEmpty ? 0 : totalMinutes / totalWorkouts

        let (currentStreak, longestStreak) = calculateStreaks(in: days) { !$0.workouts.isEmpty }

        var weekdayDist: [Int: (count: Int, avgDuration: Int)] = [:]
        let calendar = Calendar.current
        for day in days where !day.workouts.isEmpty {
            let weekday = calendar.component(.weekday, from: day.date)
            let adjusted = weekday == 1 ? 7 : weekday - 1
            let dayMinutes = day.workouts.reduce(0) { $0 + $1.duration.minutes }
            let existing = weekdayDist[adjusted] ?? (count: 0, avgDuration: 0)
            let newCount = existing.count + 1
            weekdayDist[adjusted] = (count: newCount, avgDuration: (existing.avgDuration * existing.count + dayMinutes) / newCount)
        }

        var weeklyVolume: [Date: Int] = [:]
        for day in days where !day.workouts.isEmpty {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: day.date)?.start {
                let normalizedWeekStart = calendar.startOfDay(for: weekStart)
                weeklyVolume[normalizedWeekStart, default: 0] += day.workouts.reduce(0) { $0 + $1.duration.minutes }
            }
        }

        var durationDist: [DurationRange: Int] = [:]
        for workout in allWorkouts {
            durationDist[DurationRange(minutes: workout.duration.minutes), default: 0] += 1
        }

        return WorkoutAnalytics(
            totalWorkouts: totalWorkouts,
            totalMinutes: totalMinutes,
            averageDuration: averageDuration,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weekdayDistribution: weekdayDist,
            weeklyVolume: weeklyVolume,
            durationDistribution: durationDist
        )
    }

    func calculateStreaks(in days: [DayData], condition: (DayData) -> Bool) -> (current: Int, longest: Int) {
        guard !days.isEmpty else { return (0, 0) }
        let sorted = days.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var currentStreak = 0, longestStreak = 0, tempStreak = 0
        var previousDate: Date?

        for day in sorted {
            if condition(day) {
                if let prev = previousDate,
                   (calendar.dateComponents([.day], from: day.date, to: prev).day ?? 0) == 1
                {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
                if previousDate == nil || calendar.isDateInToday(day.date) { currentStreak = tempStreak }
                previousDate = day.date
            } else {
                longestStreak = max(longestStreak, tempStreak)
                if previousDate == nil { currentStreak = 0 }
                tempStreak = 0
                previousDate = day.date
            }
        }
        return (currentStreak, max(longestStreak, tempStreak))
    }
}
