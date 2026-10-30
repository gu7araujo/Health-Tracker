//
//  TestUserDefaults.swift
//  HealthTrackerTests
//

import Foundation
import Testing

/// A UserDefaults suite for tests, named after the caller rather than a random UUID: removing a domain still
/// leaves an empty plist on the simulator (cfprefsd writes it as the test host exits), so a random name would
/// add a file every run. `init` clears what an earlier run left; call `remove()` when the test ends.
struct TestUserDefaults {
    let suiteName: String
    let defaults: UserDefaults

    init(name: String = #function) throws {
        suiteName = "test-suite-\(name)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        remove()
    }

    func remove() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
