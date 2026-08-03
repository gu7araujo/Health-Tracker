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

    /// Weeks the strip is currently paged away from today's week (0 = today's week,
    /// -1 = one week earlier). Selecting a day never moves the strip, so the helper
    /// tracks its own paging to know which week is on screen.
    private var visibleWeekOffset = 0

    private func calendarDayCell(offset: Int) -> XCUIElement {
        app.buttons[AccessibilityID.calendarDay(offset: offset)]
    }

    /// Selects the day `offset` days from today, paging the weekly strip (one week
    /// per swipe on the strip container) to the target day's week first. The paging
    /// direction is derived from the date, so it works whichever weekday today is —
    /// including when the target sits on an adjacent week's page and is off-screen
    /// (e.g. yesterday when today is a Monday). Probing the off-screen cell directly
    /// is avoided because its frame is invalid while on another page.
    private func selectDay(offset: Int) {
        let targetWeek = weekOffset(forDayOffset: offset)
        let strip = assertExists(element(AccessibilityID.calendarStrip))
        while visibleWeekOffset > targetWeek {
            strip.swipeRight() // reveal the previous week
            visibleWeekOffset -= 1
        }
        while visibleWeekOffset < targetWeek {
            strip.swipeLeft() // reveal the next week
            visibleWeekOffset += 1
        }
        let cell = calendarDayCell(offset: offset)
        assertExists(cell).tap()
        assertSelected(cell)
    }

    /// Whole weeks between today's week and the day `offset` days away, using a
    /// Monday-first Gregorian calendar to match `CalendarStrip` and the en_GB launch locale.
    private func weekOffset(forDayOffset offset: Int) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday, matching CalendarStrip + en_GB
        let today = calendar.startOfDay(for: Date())
        guard let target = calendar.date(byAdding: .day, value: offset, to: today),
              let todayWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let targetWeekStart = calendar.dateInterval(of: .weekOfYear, for: target)?.start
        else { return 0 }
        let days = calendar.dateComponents([.day], from: todayWeekStart, to: targetWeekStart).day ?? 0
        return Int((Double(days) / 7).rounded())
    }
}
