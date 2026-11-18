//
//  CalendarUITests.swift
//  HealthTrackerUITests
//

import XCTest

final class CalendarUITests: HealthTrackerUITestCase {
    /// Smoke test for the launch hook, temp-dir isolation and identifier plumbing, then the per-day store.
    func testLaunchStateAndDataIsolatedPerDay() {
        XCTContext.runActivity(named: "Launch state") { _ in
            // On the visible page right after launch, with no swipe: the lazy strip also renders the
            // neighbouring weeks, so "today's cell exists" passes on the wrong week (#85)
            let today = assertExists(calendarDayCell(offset: 0))
            assertOnVisiblePage(today)
            XCTAssertTrue(today.isSelected)
            assertExists(app.buttons[AccessibilityID.addRecordButton])
            assertExists(element(AccessibilityID.mealsEmptyState))
            assertExists(element(AccessibilityID.workoutsEmptyState))
        }

        XCTContext.runActivity(named: "Add today's meal") { _ in
            addMeal(items: ["Today lunch"])
            let todayCard = assertExists(element(AccessibilityID.mealCard(0)))
            XCTAssertTrue(todayCard.label.contains("Today lunch"))
        }

        XCTContext.runActivity(named: "Add yesterday's meal") { _ in
            selectDay(offset: -1)
            assertExists(element(AccessibilityID.mealsEmptyState))

            addMeal(items: ["Yesterday dinner"])
            XCTAssertTrue(assertExists(element(AccessibilityID.mealCard(0))).label.contains("Yesterday dinner"))
        }

        XCTContext.runActivity(named: "Back to today") { _ in
            selectDay(offset: 0)
            let card = assertExists(element(AccessibilityID.mealCard(0)))
            XCTAssertTrue(card.label.contains("Today lunch"))
            XCTAssertFalse(card.label.contains("Yesterday dinner"))
        }
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

    /// Regression for #58: with the strip paged into earlier weeks, yesterday's cell is not
    /// rendered, and chasing it by its sign ("past = left") paged further away from it.
    func testPastDaySelectableFromEarlierWeeks() {
        revealDayCell(offset: 0) // wait for the strip before swiping it
        let strip = element(AccessibilityID.calendarStrip)
        strip.swipeRight()
        // Paging back prepends earlier weeks; the strip must stay on the week it paged to.
        assertOnVisiblePage(calendarDayCell(offset: -7))
        for _ in 0 ..< 3 {
            strip.swipeRight()
        }
        assertNotExists(calendarDayCell(offset: -1))

        selectDay(offset: -1)
    }

    // MARK: - Helpers

    private func calendarDayCell(offset: Int) -> XCUIElement {
        app.buttons[AccessibilityID.calendarDay(offset: offset)]
    }

    /// Pages the horizontally-paged weekly strip until the day `offset` days from
    /// today sits fully inside the visible page, then returns it. The strip's scroll
    /// position is not guaranteed to sit on today's week — it can reset to an adjacent
    /// week on re-layout (e.g. after the add-record modal), and a day on another page
    /// reports an off-screen or clipped frame. Reachability is judged from the cell's
    /// `frame` versus the strip's viewport — never `.isHittable` or `.tap`, which hit-test
    /// an off-page cell and hard-fail with "Activation point invalid…". A rendered-but-
    /// clipped cell is nudged toward the edge it hangs off; a not-yet-rendered one is
    /// chased from the days that are rendered (later days sit to the right), since the
    /// strip can be on a week either side of the target.
    @discardableResult
    private func revealDayCell(offset: Int) -> XCUIElement {
        let strip = assertExists(element(AccessibilityID.calendarStrip))
        let cell = calendarDayCell(offset: offset)
        for _ in 0 ..< 8 {
            if cell.exists {
                let cellFrame = cell.frame
                let viewport = strip.frame
                if isOnVisiblePage(cellFrame, viewport: viewport) {
                    return cell // fully on the visible page → safe to tap
                }
                if cellFrame.midX > viewport.midX {
                    strip.swipeLeft() // clipped/off to the right → reveal the right side
                } else {
                    strip.swipeRight() // clipped/off to the left → reveal the left side
                }
            } else if (renderedDayOffset() ?? 0) < offset {
                strip.swipeLeft() // the rendered days are earlier → the target is to the right
            } else {
                strip.swipeRight() // the rendered days are later → the target is to the left
            }
        }
        return cell
    }

    /// Whether a cell's frame lies fully inside the strip's viewport. A lazy stack also renders the
    /// cells of the pages next to the visible one, so existing is not the same as being shown.
    private func isOnVisiblePage(_ cellFrame: CGRect, viewport: CGRect) -> Bool {
        cellFrame.width > 1
            && cellFrame.minX >= viewport.minX - 0.5
            && cellFrame.maxX <= viewport.maxX + 0.5
    }

    /// Waits, without swiping, until the cell is on the strip's visible page.
    private func assertOnVisiblePage(_ cell: XCUIElement, timeout: TimeInterval = 5,
                                     file: StaticString = #filePath, line: UInt = #line)
    {
        let strip = element(AccessibilityID.calendarStrip)
        var lastSeen = "nothing"
        let shown = waitUntil(timeout: timeout) {
            guard let cellFrame = (try? cell.snapshot())?.frame,
                  let viewport = (try? strip.snapshot())?.frame else { return false }
            lastSeen = "\(cellFrame) in the strip's \(viewport)"
            return isOnVisiblePage(cellFrame, viewport: viewport)
        }
        XCTAssertTrue(shown, "Expected \(cell) on the strip's visible page, last saw \(lastSeen)",
                      file: file, line: line)
    }

    /// The offset of one day cell the strip currently renders (they are contiguous, so any
    /// one tells which side a missing day is on), or `nil` when it renders none.
    private func renderedDayOffset() -> Int? {
        let rendered = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", AccessibilityID.calendarDayPrefix))
            .firstMatch
        guard rendered.exists else { return nil }
        return Int(rendered.identifier.dropFirst(AccessibilityID.calendarDayPrefix.count))
    }

    /// Selects the day `offset` days from today, paging the strip into view first.
    private func selectDay(offset: Int) {
        let cell = revealDayCell(offset: offset)
        cell.tap()
        assertSelected(cell)
    }
}
