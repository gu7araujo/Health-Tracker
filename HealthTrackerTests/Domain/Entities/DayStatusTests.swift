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

struct DayStatusTests {
    // MARK: - Color Mapping Tests

    @Test @MainActor func color_optimal_isGreen() {
        #expect(DayStatus.optimal.color == .green)
    }

    @Test @MainActor func color_moderate_isYellow() {
        #expect(DayStatus.moderate.color == .yellow)
    }

    @Test @MainActor func color_poor_isRed() {
        #expect(DayStatus.poor.color == .red)
    }

    @Test @MainActor func color_incomplete_isPrimary() {
        #expect(DayStatus.incomplete.color == .primary)
    }

    @Test @MainActor func color_noData_isNil() {
        #expect(DayStatus.noData.color == nil)
    }

    // MARK: - Equatable Tests

    @Test @MainActor func equatable_sameValues_areEqual() {
        #expect(DayStatus.optimal == DayStatus.optimal)
        #expect(DayStatus.moderate == DayStatus.moderate)
        #expect(DayStatus.poor == DayStatus.poor)
        #expect(DayStatus.incomplete == DayStatus.incomplete)
        #expect(DayStatus.noData == DayStatus.noData)
    }

    @Test @MainActor func equatable_differentValues_areNotEqual() {
        #expect(DayStatus.optimal != DayStatus.moderate)
        #expect(DayStatus.optimal != DayStatus.poor)
        #expect(DayStatus.moderate != DayStatus.poor)
        #expect(DayStatus.incomplete != DayStatus.noData)
    }

    // MARK: - Integration Tests with DayData

    @Test @MainActor func dayData_status_optimal_hasGreenColor() {
        let dayData = TestDataBuilder.makeOptimalDay()
        #expect(dayData.status.color == .green)
    }

    @Test @MainActor func dayData_status_moderate_hasYellowColor() {
        let dayData = TestDataBuilder.makeModerateDay()
        #expect(dayData.status.color == .yellow)
    }

    @Test @MainActor func dayData_status_poor_hasRedColor() {
        let dayData = TestDataBuilder.makePoorDay()
        #expect(dayData.status.color == .red)
    }

    @Test @MainActor func dayData_status_incomplete_hasPrimaryColor() {
        let dayData = TestDataBuilder.makeIncompleteDay()
        #expect(dayData.status.color == .primary)
    }

    @Test @MainActor func dayData_status_noData_hasNilColor() {
        let dayData = TestDataBuilder.makeEmptyDay()
        #expect(dayData.status.color == nil)
    }
}
