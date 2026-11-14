//
//  HealthTrackerUITestCase.swift
//  HealthTrackerUITests
//

import Synchronization
import XCTest

/// Base class for all UI tests: launches the app with an isolated temp data
/// directory (via the `-uiTesting` argument) and English locale, and provides
/// small flow helpers shared across suites.
///
/// Locale note: `en_GB` is used instead of `en_US` because it keeps English
/// labels while using a 24-hour clock, so the workout duration wheel exposes
/// hours 0-23 exactly as the app's duration model expects.
@MainActor
class HealthTrackerUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        launchRetryingOnce { app.launch() }
    }

    // MARK: - Launch

    private enum LaunchAttempt { case none, first, firstFailed(String) }

    /// Where `launchRetryingOnce` is; a `Mutex` because XCTest can record an issue from any thread.
    private let launchAttempt = Mutex(LaunchAttempt.none)

    /// Runs `launch`, and once more when that attempt records a failure. On a loaded CI
    /// simulator XCUITest can lose track of a launch that succeeded ("Application … does not
    /// have a process ID", #58), which fails a test before it starts. A second failed
    /// attempt fails the test as usual. Returns the first attempt's failures, when retried;
    /// the relaunch activity is named after them too, so a result bundle shows what was retried.
    @discardableResult
    func launchRetryingOnce(_ launch: () -> Void) -> String? {
        launchAttempt.withLock { $0 = .first }
        launch()
        let firstFailure: String? = launchAttempt.withLock { attempt in
            defer { attempt = .none }
            guard case let .firstFailed(description) = attempt else { return nil }
            return description
        }
        if let firstFailure {
            XCTContext.runActivity(named: "Relaunch: the first launch attempt failed: \(firstFailure)") { _ in
                launch()
            }
        }
        return firstFailure
    }

    /// Holds back the failures of `launchRetryingOnce`'s first attempt.
    override nonisolated func record(_ issue: XCTIssue) {
        let heldBack = launchAttempt.withLock { attempt in
            switch attempt {
            case .none: return false
            case .first: attempt = .firstFailed(issue.compactDescription)
            case let .firstFailed(earlier): attempt = .firstFailed("\(earlier); \(issue.compactDescription)")
            }
            return true
        }
        if !heldBack {
            super.record(issue)
        }
    }

    // MARK: - Element Lookup

    /// Finds an element of any type by accessibility identifier.
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @discardableResult
    func assertExists(_ element: XCUIElement, timeout: TimeInterval = 5,
                      file: StaticString = #filePath, line: UInt = #line) -> XCUIElement
    {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected element to exist: \(element)",
            file: file, line: line
        )
        return element
    }

    func assertNotExists(_ element: XCUIElement, timeout: TimeInterval = 5,
                         file: StaticString = #filePath, line: UInt = #line)
    {
        XCTAssertTrue(
            element.waitForNonExistence(timeout: timeout),
            "Expected element to disappear: \(element)",
            file: file, line: line
        )
    }

    /// Waits until the element reports `isSelected == true` (selection updates can lag taps). Polls the
    /// element itself: a predicate expectation abandons a slow accessibility query at the timeout, and
    /// on a loaded simulator one query can outlast it (#96). Polling stops only after a query that
    /// started past the deadline, so a slow query may overrun `timeout`, and a stale answer that
    /// arrives late gets one more poll. One snapshot per poll, which throws rather than fails while
    /// the element is missing.
    func assertSelected(_ element: XCUIElement, timeout: TimeInterval = 5,
                        file: StaticString = #filePath, line: UInt = #line)
    {
        let deadline = ContinuousClock.now + .seconds(timeout)
        var pollStart: ContinuousClock.Instant
        repeat {
            pollStart = .now
            if (try? element.snapshot())?.isSelected == true { return }
        } while pollStart < deadline
        XCTFail("Expected element to be selected: \(element)", file: file, line: line)
    }

    /// Swipes up until the element is on screen (List rows below the fold may not exist yet).
    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 4) {
        var swipes = 0
        while !(element.exists && element.isHittable), swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }

    /// Selects all text in the field and replaces it with the given text.
    func clearAndType(_ field: XCUIElement, with text: String) {
        field.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        field.typeText(text)
    }

    // MARK: - Flow Helpers

    /// Taps the toolbar Add button and chooses "Meal" or "Workout" in the alert.
    func openAddModal(choosing option: String) {
        assertExists(app.buttons[AccessibilityID.addRecordButton]).tap()
        let alert = app.alerts.firstMatch
        assertExists(alert)
        alert.buttons[option].tap()
        assertExists(app.buttons[AccessibilityID.modalSaveButton])
    }

    /// Saves the modal and waits for the sheet to dismiss.
    func saveModal() {
        app.buttons[AccessibilityID.modalSaveButton].tap()
        assertNotExists(app.buttons[AccessibilityID.modalSaveButton])
    }

    /// Cancels the modal and waits for the sheet to dismiss.
    func cancelModal() {
        app.buttons[AccessibilityID.modalCancelButton].tap()
        assertNotExists(app.buttons[AccessibilityID.modalCancelButton])
    }

    /// Adds a meal through the UI. Extra items are appended via the add-item button.
    func addMeal(items: [String], quantity: String? = nil, satisfaction: String? = nil) {
        openAddModal(choosing: EnglishLabel.mealOption)
        for (index, item) in items.enumerated() {
            if index > 0 {
                assertExists(app.buttons[AccessibilityID.addMealItemButton]).tap()
            }
            let field = assertExists(app.textFields[AccessibilityID.mealItemField(index)])
            field.tap()
            field.typeText(item)
        }
        if let quantity {
            selectMenuOption(picker: AccessibilityID.quantityPicker, option: quantity)
        }
        if let satisfaction {
            selectMenuOption(picker: AccessibilityID.satisfactionPicker, option: satisfaction)
        }
        saveModal()
    }

    /// Adds a workout through the UI, optionally adjusting the duration wheels and intensity.
    func addWorkout(description: String, hours: Int? = nil, minutes: Int? = nil, intensity: String? = nil) {
        openAddModal(choosing: EnglishLabel.workoutOption)
        let field = assertExists(app.textFields[AccessibilityID.workoutDescriptionField])
        field.tap()
        field.typeText(description)
        setDurationWheels(hours: hours, minutes: minutes)
        if let intensity {
            selectMenuOption(picker: AccessibilityID.intensityPicker, option: intensity)
        }
        saveModal()
    }

    /// Adjusts the wheel-style duration picker in the modal (24-hour clock under en_GB).
    func setDurationWheels(hours: Int?, minutes: Int?) {
        guard hours != nil || minutes != nil else { return }
        let picker = assertExists(element(AccessibilityID.durationPicker))
        if let hours {
            picker.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: String(format: "%02d", hours))
        }
        if let minutes {
            picker.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: String(format: "%02d", minutes))
        }
    }

    /// Taps a menu-style picker row and selects the given option from its menu.
    /// Scrolls the picker into view first so pickers below the fold (e.g. the workout
    /// intensity picker under the tall duration wheel in the medium detent) stay reliable.
    func selectMenuOption(picker identifier: String, option: String) {
        let picker = element(identifier)
        scrollTo(picker)
        assertExists(picker).tap()
        assertExists(app.buttons[option]).tap()
    }

    /// Reveals swipe actions on a list row and taps the action with the given
    /// identifier, falling back to its visible label if the identifier is not
    /// surfaced by the swipe-action host.
    func tapSwipeAction(on rowElement: XCUIElement, identifier: String, fallbackLabel: String) {
        assertExists(rowElement).swipeLeft()
        let byIdentifier = app.buttons[identifier]
        if byIdentifier.waitForExistence(timeout: 2) {
            byIdentifier.tap()
        } else {
            assertExists(app.buttons[fallbackLabel], timeout: 2).tap()
        }
    }
}
