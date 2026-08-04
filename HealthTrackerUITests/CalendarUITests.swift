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

        revealDayCell(offset: 1).tap()
        XCTAssertTrue(calendarDayCell(offset: 0).isSelected)
        XCTAssertFalse(calendarDayCell(offset: 1).isSelected)
    }

    // MARK: - Helpers

    private func calendarDayCell(offset: Int) -> XCUIElement {
        app.buttons[AccessibilityID.calendarDay(offset: offset)]
    }

    /// Pages the horizontally-paged weekly strip until the day `offset` days from
    /// today sits fully inside the visible page, then returns it. The strip's scroll
    /// position is not guaranteed to sit on today's week — it can reset to an adjacent
    /// week on re-layout (e.g. after the add-record modal, or racing the launch scroll),
    /// and a day on another page reports an off-screen or clipped frame. Reachability is
    /// judged from the cell's `frame` versus the strip's viewport — never `.isHittable`
    /// or `.tap`, which hit-test an off-page cell and hard-fail with "Activation point
    /// invalid…". A rendered-but-clipped cell is nudged toward the edge it hangs off; a
    /// not-yet-rendered one is chased in its calendar direction (future right, past left).
    @discardableResult
    private func revealDayCell(offset: Int) -> XCUIElement {
        let strip = assertExists(element(AccessibilityID.calendarStrip))
        let cell = calendarDayCell(offset: offset)
        for _ in 0 ..< 8 {
            if cell.exists {
                let cellFrame = cell.frame
                let viewport = strip.frame
                if cellFrame.width > 1,
                   cellFrame.minX >= viewport.minX - 0.5,
                   cellFrame.maxX <= viewport.maxX + 0.5
                {
                    return cell // fully on the visible page → safe to tap
                }
                if cellFrame.midX > viewport.midX {
                    strip.swipeLeft() // clipped/off to the right → reveal the right side
                } else {
                    strip.swipeRight() // clipped/off to the left → reveal the left side
                }
            } else if offset >= 0 {
                strip.swipeLeft() // future weeks are to the right
            } else {
                strip.swipeRight() // past weeks are to the left
            }
        }
        return cell
    }

    /// Selects the day `offset` days from today, paging the strip into view first.
    private func selectDay(offset: Int) {
        let cell = revealDayCell(offset: offset)
        cell.tap()
        assertSelected(cell)
    }
}
