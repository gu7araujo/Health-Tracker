//
//  LaunchUITests.swift
//  HealthTrackerUITests
//

import XCTest

final class LaunchUITests: HealthTrackerUITestCase {
    /// Regression for #58: on a loaded CI simulator XCUITest can lose track of a launch that
    /// succeeded, which failed the first test of the bundle in `setUp`. The failure is
    /// recorded by hand here: a real failed `launch()` takes minutes to give up.
    func testLaunchFailureRetriedOnceThenFailsTheTest() {
        let lostLaunch = XCTIssue(
            type: .assertionFailure,
            compactDescription: "Application 'com.gustavoaraujo.health-tracker' does not have a process ID"
        )
        let crash = XCTIssue(type: .system, compactDescription: "Application crashed")
        var attempts = 0
        let retried = launchRetryingOnce {
            attempts += 1
            if attempts == 1 {
                record(lostLaunch)
                record(crash)
            }
        }
        XCTAssertEqual(attempts, 2)
        XCTAssertEqual(retried, "\(lostLaunch.compactDescription); \(crash.compactDescription)")

        XCTExpectFailure("A launch that fails twice fails the test") {
            launchRetryingOnce { record(lostLaunch) }
        }
    }
}
