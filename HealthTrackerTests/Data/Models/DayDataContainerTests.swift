//
//  DayDataContainerTests.swift
//  HealthTrackerTests
//
//  Tests for DayDataContainer model covering Codable conformance.
//

import Foundation
@testable import HealthTracker
import Testing

struct DayDataContainerTests {
    // MARK: - Initialization Tests

    @Test @MainActor func initialization_withEmptyArray() {
        let container = DayDataContainer(days: [])

        #expect(container.days.isEmpty)
    }

    @Test @MainActor func initialization_withDays() {
        let day1 = TestDataBuilder.makeOptimalDay()
        let day2 = TestDataBuilder.makeModerateDay()
        let container = DayDataContainer(days: [day1, day2])

        #expect(container.days.count == 2)
        #expect(container.days[0] == day1)
        #expect(container.days[1] == day2)
    }

    // MARK: - Codable Tests

    @Test @MainActor func codable_roundTrip_withEmptyArray() throws {
        let original = DayDataContainer(days: [])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayDataContainer.self, from: encoded)

        #expect(decoded.days.isEmpty)
    }

    @Test @MainActor func codable_roundTrip_withSingleDay() throws {
        let day = TestDataBuilder.makeOptimalDay()
        let original = DayDataContainer(days: [day])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayDataContainer.self, from: encoded)

        #expect(decoded.days.count == 1)
        #expect(decoded.days[0] == day)
    }

    @Test @MainActor func codable_roundTrip_withMultipleDays() throws {
        let day1 = TestDataBuilder.makeOptimalDay(date: TestDataBuilder.fixedDate)
        let day2 = TestDataBuilder.makeModerateDay(date: TestDataBuilder.fixedDatePlusOne)
        let day3 = TestDataBuilder.makePoorDay(date: TestDataBuilder.fixedDate)
        let original = DayDataContainer(days: [day1, day2, day3])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayDataContainer.self, from: encoded)

        #expect(decoded.days.count == 3)
        #expect(decoded.days[0] == day1)
        #expect(decoded.days[1] == day2)
        #expect(decoded.days[2] == day3)
    }

    @Test @MainActor func codable_preservesAllDayDataProperties() throws {
        let day = TestDataBuilder.makeOptimalDay()
        let original = DayDataContainer(days: [day])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayDataContainer.self, from: encoded)

        let decodedDay = decoded.days[0]
        #expect(decodedDay.date == day.date)
        #expect(decodedDay.meals.count == day.meals.count)
        #expect(decodedDay.workouts.count == day.workouts.count)
        #expect(decodedDay.water == day.water)
        #expect(decodedDay.mood == day.mood)
    }

    @Test @MainActor func codable_handlesEmptyDays() throws {
        let emptyDay = TestDataBuilder.makeEmptyDay()
        let original = DayDataContainer(days: [emptyDay])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DayDataContainer.self, from: encoded)

        #expect(decoded.days.count == 1)
        #expect(decoded.days[0].meals.isEmpty)
        #expect(decoded.days[0].workouts.isEmpty)
        #expect(decoded.days[0].water == nil)
        #expect(decoded.days[0].mood == nil)
    }
}
