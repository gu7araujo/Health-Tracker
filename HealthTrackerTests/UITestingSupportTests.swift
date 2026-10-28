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
}
