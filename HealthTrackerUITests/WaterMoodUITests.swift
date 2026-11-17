//
//  WaterMoodUITests.swift
//  HealthTrackerUITests
//

import XCTest

final class WaterMoodUITests: HealthTrackerUITestCase {
    func testWaterStartsAtZero() {
        let label = assertExists(element(AccessibilityID.waterValueLabel))
        XCTAssertTrue(label.label.hasPrefix("0.0"), "Expected water to start at 0.0, got: \(label.label)")
    }

    func testAdjustWaterSlider() {
        let slider = app.sliders[AccessibilityID.waterSlider]
        scrollTo(slider)
        assertExists(slider).adjust(toNormalizedSliderPosition: 0.5)

        // Read through snapshots: right after the drag one label query can outlast a 5 s wait on a
        // loaded simulator, and a failed query records the test as failed (#80)
        let label = element(AccessibilityID.waterValueLabel)
        var text = ""
        // Normalized slider position is approximate on SwiftUI sliders (observed 2.0-2.6
        // for the midpoint) — assert the drag moved the value into the middle band
        let midRange = waitUntil {
            text = (try? label.snapshot())?.label ?? ""
            return (1.0 ... 4.0).contains(Double(text.replacingOccurrences(of: " L", with: "")) ?? -1)
        }
        XCTAssertTrue(midRange, "Expected a mid-range water value, got: \(text.isEmpty ? "<no label>" : text)")
    }

    func testSelectMood() {
        let good = app.buttons[AccessibilityID.moodButtonGood]
        scrollTo(good)
        assertExists(good).tap()
        assertSelected(good)
    }

    func testChangeMood() {
        let good = app.buttons[AccessibilityID.moodButtonGood]
        let sad = app.buttons[AccessibilityID.moodButtonSad]
        scrollTo(good)
        assertExists(good).tap()
        assertSelected(good)

        assertExists(sad).tap()
        assertSelected(sad)
        XCTAssertFalse(good.isSelected)
    }
}
