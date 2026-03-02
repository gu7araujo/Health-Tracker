//
//  DayStatusTests.swift
//  HealthTrackerTests
//
//  Tests for DayStatus enum covering color mappings for each status.
//

import Foundation
@testable import HealthTracker
import SwiftUI
import Testing

@MainActor
struct DayStatusTests {
    // MARK: - Color Mapping Tests

    @Test(arguments: [
        (DayStatus.optimal, Color?.some(.green)),
        (.moderate, .some(.yellow)),
        (.poor, .some(.red)),
        (.incomplete, .some(.primary)),
        (.noData, nil),
    ])
    func color_mappings(status: DayStatus, expectedColor: Color?) {
        #expect(status.color == expectedColor)
    }

    // MARK: - Equatable Tests

    @Test func equatable_sameValues_areEqual() {
        #expect(DayStatus.optimal == DayStatus.optimal)
        #expect(DayStatus.moderate == DayStatus.moderate)
        #expect(DayStatus.poor == DayStatus.poor)
        #expect(DayStatus.incomplete == DayStatus.incomplete)
        #expect(DayStatus.noData == DayStatus.noData)
    }

    @Test func equatable_differentValues_areNotEqual() {
        #expect(DayStatus.optimal != DayStatus.moderate)
        #expect(DayStatus.optimal != DayStatus.poor)
        #expect(DayStatus.moderate != DayStatus.poor)
        #expect(DayStatus.incomplete != DayStatus.noData)
    }

    // MARK: - Integration Tests with DayData

    @Test func dayData_status_optimal_hasGreenColor() {
        let dayData = TestDataBuilder.makeOptimalDay()
        #expect(dayData.status.color == .green)
    }

    @Test func dayData_status_moderate_hasYellowColor() {
        let dayData = TestDataBuilder.makeModerateDay()
        #expect(dayData.status.color == .yellow)
    }

    @Test func dayData_status_poor_hasRedColor() {
        let dayData = TestDataBuilder.makePoorDay()
        #expect(dayData.status.color == .red)
    }

    @Test func dayData_status_incomplete_hasPrimaryColor() {
        let dayData = TestDataBuilder.makeIncompleteDay()
        #expect(dayData.status.color == .primary)
    }

    @Test func dayData_status_noData_hasNilColor() {
        let dayData = TestDataBuilder.makeEmptyDay()
        #expect(dayData.status.color == nil)
    }
}
