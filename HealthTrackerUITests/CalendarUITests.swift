//
//  CalendarUITests.swift
//  HealthTrackerUITests
//

import XCTest

final class CalendarUITests: HealthTrackerUITestCase {
    /// Smoke test: validates the launch hook, temp-dir isolation, and identifier plumbing.
    func testTodaySelectedOnLaunchAndEmptyStates() {
        let today = assertExists(calendarDayCell(offset: 0))
        XCTAssertTrue(today.isSelected)
        assertExists(app.buttons[AccessibilityID.addRecordButton])
        assertExists(element(AccessibilityID.mealsEmptyState))
        assertExists(element(AccessibilityID.workoutsEmptyState))
    }

    func testDataIsolatedPerDay() {
        addMeal(items: ["Today lunch"])
        let todayCard = assertExists(element(AccessibilityID.mealCard(0)))
        XCTAssertTrue(todayCard.label.contains("Today lunch"))

        selectDay(offset: -1)
        assertExists(element(AccessibilityID.mealsEmptyState))

        addMeal(items: ["Yesterday dinner"])
        XCTAssertTrue(assertExists(element(AccessibilityID.mealCard(0))).label.contains("Yesterday dinner"))

        selectDay(offset: 0)
        let card = assertExists(element(AccessibilityID.mealCard(0)))
        XCTAssertTrue(card.label.contains("Today lunch"))
        XCTAssertFalse(card.label.contains("Yesterday dinner"))
    }

    func testFutureDayNotSelectable() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let today = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            return XCTFail("Could not compute tomorrow")
        }
        try XCTSkipUnless(
            calendar.isDate(tomorrow, equalTo: today, toGranularity: .weekOfYear),
            "No future day is visible when today is the last day of the week"
        )

        assertExists(calendarDayCell(offset: 1)).tap()
        XCTAssertTrue(calendarDayCell(offset: 0).isSelected)
        XCTAssertFalse(calendarDayCell(offset: 1).isSelected)
    }

    // MARK: - Helpers

    private func calendarDayCell(offset: Int) -> XCUIElement {
        app.buttons[AccessibilityID.calendarDay(offset: offset)]
    }

    /// Selects a day in the strip, paging back one week first when the target
    /// cell is off-screen (e.g. yesterday when today is the first day of the week).
    private func selectDay(offset: Int) {
        let cell = calendarDayCell(offset: offset)
        if !cell.exists || !cell.isHittable {
            calendarDayCell(offset: 0).swipeRight()
        }
        assertExists(cell).tap()
        XCTAssertTrue(cell.isSelected)
    }
}
