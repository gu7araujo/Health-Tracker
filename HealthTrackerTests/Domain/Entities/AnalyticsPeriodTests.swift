//
//  AnalyticsPeriodTests.swift
//  HealthTrackerTests
//
//  Tests for AnalyticsPeriod covering display names, date ranges, and locale behavior.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct AnalyticsPeriodTests {
    // MARK: - Display Name Tests

    @Test(arguments: [
        (AnalyticsPeriod.thisWeek, "period_this_week"),
        (.last7Days, "period_last_7_days"),
        (.last30Days, "period_last_30_days")
    ])
    func displayName_predefinedPeriods_usesLocalizationKeys(period: AnalyticsPeriod, localizationKey: String) {
        let expected = NSLocalizedString(localizationKey, comment: "")
        #expect(period.displayName == expected)
    }

    @Test func displayName_customPeriod_usesSystemLocale() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let period = AnalyticsPeriod.custom(start: yesterday, end: today)

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale.current
        let expected = "\(formatter.string(from: yesterday)) - \(formatter.string(from: today))"

        #expect(period.displayName == expected)
    }

    // MARK: - ID Tests

    @Test func id_predefinedCases_areStable() {
        #expect(AnalyticsPeriod.thisWeek.id == "thisWeek")
        #expect(AnalyticsPeriod.last7Days.id == "last7Days")
        #expect(AnalyticsPeriod.last30Days.id == "last30Days")
    }

    @Test func predefinedCases_containsAllThree() {
        let cases = AnalyticsPeriod.predefinedCases
        #expect(cases.count == 3)
        #expect(cases.contains(.thisWeek))
        #expect(cases.contains(.last7Days))
        #expect(cases.contains(.last30Days))
    }
}
