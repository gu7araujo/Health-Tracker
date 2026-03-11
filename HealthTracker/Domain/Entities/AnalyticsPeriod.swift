//
//  AnalyticsPeriod.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// Represents a time period for analytics calculations.
/// Provides date ranges for filtering historical health data.
enum AnalyticsPeriod: Equatable, Identifiable, Hashable {
    case thisWeek
    case last7Days
    case last30Days
    case custom(start: Date, end: Date)

    var id: String {
        switch self {
        case .thisWeek: "thisWeek"
        case .last7Days: "last7Days"
        case .last30Days: "last30Days"
        case let .custom(start, end):
            "custom_\(start.timeIntervalSince1970)_\(end.timeIntervalSince1970)"
        }
    }

    /// Localized display name for the period
    var displayName: String {
        switch self {
        case .thisWeek:
            return String(localized: "period_this_week")
        case .last7Days:
            return String(localized: "period_last_7_days")
        case .last30Days:
            return String(localized: "period_last_30_days")
        case let .custom(start, end):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.locale = Locale.current
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }

    /// Calculates the date range for this period
    var dateRange: ClosedRange<Date> {
        let calendar = calendar
        let today = calendar.startOfDay(for: Date())

        switch self {
        case .thisWeek:
            // Get Monday of current week
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today),
                  let startOfWeek = calendar.date(byAdding: .day, value: 0, to: weekInterval.start)
            else {
                return today ... today
            }
            return startOfWeek ... today

        case .last7Days:
            // Rolling 7 days from today
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
                return today ... today
            }
            return sevenDaysAgo ... today

        case .last30Days:
            // Rolling 30 days from today
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today) else {
                return today ... today
            }
            return thirtyDaysAgo ... today

        case let .custom(start, end):
            // Use start of day for both dates
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.startOfDay(for: end)
            return startOfDay ... endOfDay
        }
    }

    /// Returns the predefined period cases (excludes custom)
    static var predefinedCases: [AnalyticsPeriod] {
        [.thisWeek, .last7Days, .last30Days]
    }

    /// Calendar configuration using system locale and timezone, with Monday as first weekday
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 2 // Monday
        return calendar
    }
}
