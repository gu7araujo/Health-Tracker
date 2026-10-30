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
final class UserDefaultsDataSourceTests {
    // MARK: - Test Helpers

    /// The UserDefaults suite every test here uses (each test has its own storage key), cleared in `deinit`
    private let suite: TestUserDefaults
    private var testDefaults: UserDefaults {
        suite.defaults
    }

    init() throws {
        suite = try TestUserDefaults(name: "UserDefaultsDataSourceTests")
    }

    isolated deinit {
        suite.remove()
    }

    @Test func deinit_removesTestSuite() throws {
        var tests: UserDefaultsDataSourceTests? = try UserDefaultsDataSourceTests()
        let suite = try #require(tests).suite
        suite.defaults.set(true, forKey: "probe")

        tests = nil

        #expect(suite.defaults.object(forKey: "probe") == nil)
    }

    // MARK: - Load Tests

    @Test func load_returnsEmptyArray_whenNoData() {
        let dataSource = UserDefaultsDataSource(
            userDefaults: testDefaults,
            storageKey: "test-key-\(UUID().uuidString)"
        )

        let result = dataSource.load()

        #expect(result.isEmpty)
    }

    @Test func load_returnsEmptyArray_whenCorruptedData() {
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

    // MARK: - Save and Load Round-Trip Tests

    @Test func saveAndLoad_roundTrip_preservesData() throws {
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

    @Test func saveAndLoad_roundTrip_withSingleDay() throws {
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

    @Test func saveAndLoad_roundTrip_withEmptyArray() {
        let key = "test-key-\(UUID().uuidString)"
        let dataSource = UserDefaultsDataSource(
            userDefaults: testDefaults,
            storageKey: key
        )

        dataSource.save([])
        let loadedDays = dataSource.load()

        #expect(loadedDays.isEmpty)
    }

    @Test func save_overwritesPreviousData() throws {
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

    @Test func save_keepsPreviousData_whenEncodingFails() throws {
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

    // MARK: - Data Integrity Tests

    @Test func load_filtersOutEmptyDays() throws {
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

    @Test func saveAndLoad_preservesAllDayDataProperties() throws {
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
