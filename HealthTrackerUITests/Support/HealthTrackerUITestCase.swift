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

    /// Waits until the element exists, through `waitUntil` and `snapshot()`: when one query outlasts
    /// `waitForExistence`'s timeout, XCTest re-checks with a query that can retry for minutes and then
    /// records "Timed out while evaluating UI query" (#111).
    @discardableResult
    func assertExists(_ element: XCUIElement, timeout: TimeInterval = 5,
                      file: StaticString = #filePath, line: UInt = #line) -> XCUIElement
    {
        if !waitUntil(timeout: timeout, { isPresent(element) }) {
            XCTFail("Expected element to exist: \(element)", file: file, line: line)
        }
        return element
    }

    /// Waits until the element is gone, through `waitUntil` and `snapshot()` like `assertExists`. Only
    /// `snapshot()`'s "no matches" error counts as gone: a query that timed out throws too (#129).
    func assertNotExists(_ element: XCUIElement, timeout: TimeInterval = 5,
                         file: StaticString = #filePath, line: UInt = #line)
    {
        if !waitUntil(timeout: timeout, { isMissing(element) }) {
            XCTFail("Expected element to disappear: \(element)", file: file, line: line)
        }
    }

    /// The error `snapshot()` throws when its query matches nothing: "No matches found for first query
    /// match sequence".
    private static let noMatchesError = (domain: "com.apple.dt.xctest.ui-testing.error", code: 10008)

    private func isPresent(_ element: XCUIElement) -> Bool {
        (try? element.snapshot()) != nil
    }

    private func isMissing(_ element: XCUIElement) -> Bool {
        do {
            _ = try element.snapshot()
            return false
        } catch {
            let error = error as NSError
            return (error.domain, error.code) == Self.noMatchesError
        }
    }

    /// Polls `condition` until it holds, returning whether it did. Polls directly: a predicate
    /// expectation abandons a slow accessibility query at the timeout, and on a loaded simulator one
    /// query can outlast it (#96). Polling stops only after a query that started past the deadline, so
    /// a slow query may overrun `timeout`, and a stale answer that arrives late gets one more poll.
    /// Read elements through `snapshot()`, which throws rather than fails while an element is missing.
    func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = ContinuousClock.now + .seconds(timeout)
        var pollStart: ContinuousClock.Instant
        repeat {
            pollStart = .now
            if condition() { return true }
        } while pollStart < deadline
        return false
    }

    /// Waits until the element reports `isSelected == true` (selection updates can lag taps).
    func assertSelected(_ element: XCUIElement, timeout: TimeInterval = 5,
                        file: StaticString = #filePath, line: UInt = #line)
    {
        if waitUntil(timeout: timeout, { (try? element.snapshot())?.isSelected == true }) { return }
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
        enterText(text, into: field, taps: 3)
    }

    /// Taps the field, waits until it holds keyboard focus, then types. Typing straight after the tap
    /// can land while a sheet still animates: "Neither element nor any descendant has keyboard focus" (#116).
    /// The runner's first call waits up to 30 s: a fresh simulator's first keyboard has missed a 5 s
    /// focus wait on CI (#109). Later calls keep 5 s, so a broken field still fails fast.
    /// Not named `type`, which would hide Swift's `type(of:)` in every suite.
    func enterText(_ text: String, into field: XCUIElement, taps: Int = 1,
                   file: StaticString = #filePath, line: UInt = #line)
    {
        field.tap(withNumberOfTaps: taps, numberOfTouches: 1)
        var attributeMissing = false
        let timeout: TimeInterval = Self.firstKeyboardAttempted ? 5 : 30
        Self.firstKeyboardAttempted = true
        let focused = waitUntil(timeout: timeout) {
            guard let snapshot = (try? field.snapshot()) as? NSObject else { return false }
            attributeMissing = !snapshot.responds(to: NSSelectorFromString(Self.keyboardFocusKey))
            return attributeMissing || snapshot.value(forKey: Self.keyboardFocusKey) as? Bool == true
        }
        if attributeMissing {
            XCTFail("Snapshots no longer expose \(Self.keyboardFocusKey); update enterText", file: file, line: line)
        } else if focused {
            field.typeText(text)
        } else {
            XCTFail("Expected keyboard focus before typing: \(field)", file: file, line: line)
        }
    }

    /// The snapshot attribute `typeText` checks: the public `hasFocus` stays false on an iOS text field
    /// that holds the keyboard (seen on iOS 26.5 and 27.2).
    private static let keyboardFocusKey = "hasKeyboardFocus"

    /// Whether this runner process has called `enterText` yet; only that first call gets the long wait.
    private static var firstKeyboardAttempted = false

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
            enterText(item, into: assertExists(app.textFields[AccessibilityID.mealItemField(index)]))
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
        enterText(description, into: assertExists(app.textFields[AccessibilityID.workoutDescriptionField]))
        // Intensity before the wheels: reaching its picker swipes the sheet, and a swipe that
        // lands on the duration wheel spins it
        if let intensity {
            selectMenuOption(picker: AccessibilityID.intensityPicker, option: intensity)
        }
        setDurationWheels(hours: hours, minutes: minutes)
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
        if waitUntil(timeout: 2, { isPresent(byIdentifier) }) {
            byIdentifier.tap()
        } else {
            assertExists(app.buttons[fallbackLabel], timeout: 2).tap()
        }
    }
}
