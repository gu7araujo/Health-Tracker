//
//  RecordedDayData.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 02/07/26.
//

import Foundation

/// A day with at least one recorded health category.
/// Parse, don't validate: the failable init is the only construction path,
/// making it impossible to represent an empty day as `RecordedDayData`.
struct RecordedDayData: Equatable, Identifiable {
    /// The underlying day data, guaranteed to have at least one recorded category.
    let dayData: DayData

    var id: Date { dayData.date }

    /// Parses a `DayData` into a `RecordedDayData`.
    /// Returns nil if the day has no recorded health data
    /// (empty meals, empty workouts, no water, no mood).
    init?(_ dayData: DayData) {
        guard !dayData.meals.isEmpty || !dayData.workouts.isEmpty
            || dayData.water != nil || dayData.mood != nil
        else {
            return nil
        }
        self.dayData = dayData
    }
}
