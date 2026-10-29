//
//  UITestingSupportTests.swift
//  HealthTrackerTests
//

@testable import HealthTracker
import Testing

@MainActor
struct UITestingSupportTests {
    @Test func isHostingUnitTests_isTrueInsideTheUnitTestHost() {
        #expect(UITestingSupport.isHostingUnitTests)
    }

    @Test func hostsUnitTests_isTrueOnlyWithAnXCTestConfiguration() {
        #expect(UITestingSupport.hostsUnitTests(environment: ["XCTestConfigurationFilePath": "/tmp/x"]))
        #expect(!UITestingSupport.hostsUnitTests(environment: [:]))
    }

    @Test func skipsStartup_isTrueInsideTheUnitTestHost() {
        #expect(UITestingSupport.skipsStartup)
    }
}
