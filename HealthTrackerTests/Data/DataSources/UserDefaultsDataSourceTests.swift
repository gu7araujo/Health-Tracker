//
//  UserDefaultsDataSourceTests.swift
//  HealthTrackerTests
//
//  Tests for UserDefaultsDataSource covering save/load operations with isolated UserDefaults.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct UserDefaultsDataSourceTests {
    // MARK: - Test Helpers

    /// Runs `body` with an isolated UserDefaults suite, then removes the suite so no plist leaks
    private func withTestUserDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
        let suiteName = "test-suite-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        try body(defaults)
    }

    @Test func withTestUserDefaults_removesSuiteAfterwards() {
        var suite: UserDefaults?
        withTestUserDefaults { defaults in
            defaults.set(true, forKey: "probe")
            suite = defaults
        }

        #expect(suite?.object(forKey: "probe") == nil)
    }

    // MARK: - Load Tests

    @Test func load_returnsEmptyArray_whenNoData() {
        withTestUserDefaults { testDefaults in
            let dataSource = UserDefaultsDataSource(
                userDefaults: testDefaults,
                storageKey: "test-key-\(UUID().uuidString)"
            )

            let result = dataSource.load()

            #expect(result.isEmpty)
        }
    }

    @Test func load_returnsEmptyArray_whenCorruptedData() {
        withTestUserDefaults { testDefaults in
            let key = "test-key-\(UUID().uuidString)"
            // Store invalid JSON data
            testDefaults.set(Data("corrupted data".utf8), forKey: key)

            let dataSource = UserDefaultsDataSource(
                userDefaults: testDefaults,
                storageKey: key
            )

            let result = dataSource.load()

            #expect(result.isEmpty)
        }
    }

    // MARK: - Save and Load Round-Trip Tests

    @Test func saveAndLoad_roundTrip_preservesData() throws {
        try withTestUserDefaults { testDefaults in
            let key = "test-key-\(UUID().uuidString)"
            let dataSource = UserDefaultsDataSource(
                userDefaults: testDefaults,
                storageKey: key
            )

            let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
            let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
            let originalDays = [day1, day2]

            dataSource.save(originalDays)
            let loadedDays = dataSource.load()

            #expect(loadedDays.count == 2)
            #expect(loadedDays[0].dayData == day1.dayData)
            #expect(loadedDays[1].dayData == day2.dayData)
        }
    }

    @Test func saveAndLoad_roundTrip_withSingleDay() throws {
        try withTestUserDefaults { testDefaults in
            let key = "test-key-\(UUID().uuidString)"
            let dataSource = UserDefaultsDataSource(
                userDefaults: testDefaults,
                storageKey: key
            )

            let day = try #require(TestDataBuilder.makeRecordedOptimalDay())
            dataSource.save([day])
            let loadedDays = dataSource.load()

            #expect(loadedDays.count == 1)
            #expect(loadedDays[0].dayData == day.dayData)
        }
    }

    @Test func saveAndLoad_roundTrip_withEmptyArray() {
        withTestUserDefaults { testDefaults in
            let key = "test-key-\(UUID().uuidString)"
            let dataSource = UserDefaultsDataSource(
                userDefaults: testDefaults,
                storageKey: key
            )

            dataSource.save([])
            let loadedDays = dataSource.load()

            #expect(loadedDays.isEmpty)
        }
    }

    @Test func save_overwritesPreviousData() throws {
        try withTestUserDefaults { testDefaults in
            let key = "test-key-\(UUID().uuidString)"
            let dataSource = UserDefaultsDataSource(
                userDefaults: testDefaults,
                storageKey: key
            )

            // Save initial data
            let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay())
            dataSource.save([day1])

            // Save new data
            let day2 = try #require(TestDataBuilder.makeRecordedModerateDay())
            dataSource.save([day2])

            let loadedDays = dataSource.load()

            #expect(loadedDays.count == 1)
            #expect(loadedDays[0].dayData == day2.dayData)
        }
    }

    @Test func save_keepsPreviousData_whenEncodingFails() throws {
        try withTestUserDefaults { testDefaults in
            let key = "test-key-\(UUID().uuidString)"
            let dataSource = UserDefaultsDataSource(
                userDefaults: testDefaults,
                storageKey: key
            )
            let savedDay = try #require(TestDataBuilder.makeRecordedOptimalDay())
            dataSource.save([savedDay])

            // JSONEncoder throws on a non-finite Double
            let unencodableDay = try #require(
                TestDataBuilder.makeRecordedDayData(from: TestDataBuilder.makeDayData(water: .nan))
            )
            dataSource.save([unencodableDay])

            #expect(dataSource.load() == [savedDay])
        }
    }

    // MARK: - Data Integrity Tests

    @Test func load_filtersOutEmptyDays() throws {
        try withTestUserDefaults { testDefaults in
            let key = "test-key-\(UUID().uuidString)"

            // Manually create a container with empty day
            let emptyDay = TestDataBuilder.makeEmptyDay()
            let validDay = TestDataBuilder.makeOptimalDay()
            let container = DayDataContainer(days: [emptyDay, validDay])

            let encoded = try JSONEncoder().encode(container)
            testDefaults.set(encoded, forKey: key)

            let dataSource = UserDefaultsDataSource(
                userDefaults: testDefaults,
                storageKey: key
            )

            let loadedDays = dataSource.load()

            // Empty day should be filtered out
            #expect(loadedDays.count == 1)
            #expect(loadedDays[0].dayData == validDay)
        }
    }

    @Test func saveAndLoad_preservesAllDayDataProperties() throws {
        try withTestUserDefaults { testDefaults in
            let key = "test-key-\(UUID().uuidString)"
            let dataSource = UserDefaultsDataSource(
                userDefaults: testDefaults,
                storageKey: key
            )

            let original = try #require(TestDataBuilder.makeRecordedOptimalDay())
            dataSource.save([original])
            let loaded = dataSource.load()

            let loadedDay = try #require(loaded.first)
            #expect(loadedDay.dayData.date == original.dayData.date)
            #expect(loadedDay.dayData.meals.count == original.dayData.meals.count)
            #expect(loadedDay.dayData.workouts.count == original.dayData.workouts.count)
            #expect(loadedDay.dayData.water == original.dayData.water)
            #expect(loadedDay.dayData.mood == original.dayData.mood)
        }
    }
}
