//
//  LoggerFactoryTests.swift
//  HealthTrackerTests
//
//  Tests for LoggerFactory, verifying each layer factory returns a usable
//  LoggerProtocol that logs without crashing.
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct LoggerFactoryTests {
    @Test func domainLogger_returnsUsableLogger() {
        let logger = LoggerFactory.domainLogger(category: "Test")
        logger.debug("domain logger message")
    }

    @Test func dataLogger_returnsUsableLogger() {
        let logger = LoggerFactory.dataLogger(category: "Test")
        logger.info("data logger message")
    }

    @Test func presentationLogger_returnsUsableLogger() {
        let logger = LoggerFactory.presentationLogger(category: "Test")
        logger.warning("presentation logger message")
    }
}
