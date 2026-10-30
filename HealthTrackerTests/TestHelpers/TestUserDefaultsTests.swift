//
//  TestUserDefaultsTests.swift
//  HealthTrackerTests
//

import Foundation
import Testing

@MainActor
struct TestUserDefaultsTests {
    @Test func suiteName_isTheSameEveryRun() throws {
        #expect(try TestUserDefaults().suiteName == TestUserDefaults().suiteName)
    }

    @Test func init_clearsWhatAnEarlierRunLeft() throws {
        try TestUserDefaults().defaults.set(true, forKey: "probe")

        let suite = try TestUserDefaults()
        defer { suite.remove() }

        #expect(suite.defaults.object(forKey: "probe") == nil)
    }

    @Test func remove_clearsTheSuite() throws {
        let suite = try TestUserDefaults()
        suite.defaults.set(true, forKey: "probe")

        suite.remove()

        #expect(try #require(UserDefaults(suiteName: suite.suiteName)).object(forKey: "probe") == nil)
    }
}
