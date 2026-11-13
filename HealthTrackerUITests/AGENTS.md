# UI Test Suite

The end-to-end target. Built on **XCUITest**, each suite launches the real app on a simulator and drives it as a black box — tapping, typing, and swiping through user flows, then asserting on accessibility labels. Every test relaunches the app fresh into an isolated temp store (via `-uiTesting`), so suites share no state. Pure logic and view-model behaviour live in the separate `HealthTrackerTests` target.

## Support

The shared machinery every suite leans on, all on `HealthTrackerUITestCase`:

- **Launch** — `setUp` relaunches the app with `-uiTesting` (`HealthTracker/UITestingSupport.swift`: temp-dir store, skipped migration + permission prompts) forced to English `en_GB`, through `launchRetryingOnce`: a first launch that records a failure is relaunched once (#58, XCUITest losing a launch that succeeded). The 24-hour `en_GB` clock exposes the workout duration wheel as hours 0-23, exactly as the duration model expects.
- **Lookup + waits** — `element(_:)` resolves any element by identifier; `assertExists` / `assertNotExists` / `assertSelected` poll for a condition; `scrollTo` swipes an off-screen row into view. All time out rather than sleep.
- **Flow helpers** — `openAddModal`, `addMeal`, `addWorkout`, `saveModal`, `cancelModal`, `selectMenuOption`, `setDurationWheels`, `tapSwipeAction`. Compose a flow from these rather than re-scripting taps.

The `Support/` files are also members of the `HealthTrackerIntentsUITests` target (the App Intents suite, on iOS 27), so a new `Support` file needs both checkboxes. That suite's own conventions: `HealthTrackerIntentsUITests/AGENTS.md`.

## Rules

Black-box and isolated — each test drives the shipping app through its accessibility surface, nothing else.

<rule_1>
**XCUITEST, NOT SWIFT TESTING** — `import XCTest`; subclass `HealthTrackerUITestCase`; name cases `func testSubjectExpectation()` with `XCTAssert` checks. No `@testable import` — reach the app only through `app` and accessibility identifiers, never its internal types. Enforced by SwiftLint rule `ui_tests_no_testable_import`. The target builds in Swift 6 mode and `XCUIApplication` / `XCUIElement` are main-actor API, so `HealthTrackerUITestCase` is `@MainActor` (suites inherit it) and launches in `override func setUp() async throws`; keep new overrides and helpers on the main actor. The exception is `record(_:)`, which XCTest calls from any thread: its override is nonisolated and keeps its state in a `Mutex`.
</rule_1>

<rule_2>
**TARGET BY IDENTIFIER, ASSERT BY LABEL** — locate elements with `AccessibilityID` identifiers; assert on visible content via `element.label.contains(...)`. Alert buttons and menu picker options surface no identifier, so select and assert those through `EnglishLabel`. Both files are hand-mirrored — when the app adds or renames an identifier, update `AccessibilityID` (`scripts/fitness/accessibility-ids.sh` fails on an ID the app doesn't declare); when a user-facing string changes, update `EnglishLabel` to match `en.lproj/Localizable.strings`.
</rule_2>

<rule_3>
**WAIT, NEVER SLEEP** — selection, sheet dismissal, and swipe-action reveal all lag the action that triggers them. Gate the next step on `assertExists` / `assertNotExists` / `assertSelected`, which poll to a timeout. Never assert immediately after a tap and never insert a fixed delay. Enforced by SwiftLint rule `ui_tests_no_sleep`.
</rule_3>

<rule_4>
**SCROLL BEFORE YOU TAP** — SwiftUI `List` rows and pickers below the fold may not exist yet, and controls pushed past the sheet's bottom edge report hittable while taps land dead. `scrollTo` (or swipe the list) the target into view first; reveal card swipe actions through `tapSwipeAction`, which falls back to the visible label when the identifier is not surfaced by the swipe host. Reach a `CalendarStrip` day through `CalendarUITests.revealDayCell`, which swipes the `calendarStrip` container until the cell is hittable. The strip is a paged week view (weeks start Monday) that can reset to an adjacent week on re-layout (after a modal, or racing the launch scroll), so a direct `.tap()` on a day cell can land on an off-screen or clipped frame and record `"Activation point invalid…"`.
</rule_4>

<rule_5>
**COMPOSE FLOWS FROM HELPERS** — build a scenario from the base-class flow helpers rather than re-scripting the modal tap-by-tap; a new flow that repeats across suites earns a helper on `HealthTrackerUITestCase`. UI tests are slow — each launches the app — so cover whole user journeys here and leave branch-level logic to `HealthTrackerTests`. Adding a feature or fixing a bug ends green; see the root **Workflow** for the red → green loop and the UI-test commands.
</rule_5>

<rule_6>
**EVERY UI FAILURE GETS AN OWNER** — a UI-test failure seen while verifying, locally or on CI, ends in one of two places: fixed in the PR, or recorded on a `flaky-test` issue (filed, or commented on) with the run id (`issue-tracking` skill). A single `Timed out while evaluating UI query` earns one rerun of that test alone before you diagnose it. A PR that changes a UI test pastes its pass count over 20 runs (`RunSomeTests` with that test, repeated; `-test-iterations 20` under the root runner rule's `xcodebuild` fallback); a `Support/` change does the same for one test per changed helper.
</rule_6>
