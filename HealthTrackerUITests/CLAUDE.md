# UI Test Suite

The end-to-end target. Built on **XCUITest**, each suite launches the real app on a simulator and drives it as a black box — tapping, typing, and swiping through user flows, then asserting on accessibility labels. Every test relaunches the app fresh into an isolated temp store (via `-uiTesting`), so suites share no state. Pure logic and view-model behaviour live in the separate `HealthTrackerTests` target.

## Directory Map

| Directory / File | Type | Responsibility |
|---|---|---|
| `MealFlowUITests.swift` | suite | Add/edit/delete meals, item add/remove, five-item cap, quantity/satisfaction pickers, cancel-discards |
| `WorkoutFlowUITests.swift` | suite | Add/edit/delete workouts, wheel-style duration, intensity picker |
| `WaterMoodUITests.swift` | suite | Water slider start value + drag band, mood select and change |
| `CalendarUITests.swift` | suite | Launch smoke test, per-day data isolation, future-day-not-selectable guard |
| `Support/HealthTrackerUITestCase.swift` | base class | Isolated launch, element lookup, waits, and flow helpers — every suite subclasses it |
| `Support/AccessibilityID.swift` | mirror | Identifiers copied from `HealthTracker/Presentation/AccessibilityID.swift` (UI tests cannot import app types) |
| `Support/EnglishLabel.swift` | mirror | English labels for elements that carry no identifier (alert buttons, menu picker options) |

## Support

The shared machinery every suite leans on, all on `HealthTrackerUITestCase`:

- **Launch** — `setUp` relaunches the app with `-uiTesting` (temp-dir store, skipped migration + permission prompts) forced to English `en_GB`. The 24-hour `en_GB` clock exposes the workout duration wheel as hours 0-23, exactly as the duration model expects.
- **Lookup + waits** — `element(_:)` resolves any element by identifier; `assertExists` / `assertNotExists` / `assertSelected` poll for a condition; `scrollTo` swipes an off-screen row into view. All time out rather than sleep.
- **Flow helpers** — `openAddModal`, `addMeal`, `addWorkout`, `saveModal`, `cancelModal`, `selectMenuOption`, `setDurationWheels`, `tapSwipeAction`. Compose a flow from these rather than re-scripting taps.

## Rules

Black-box and isolated — each test drives the shipping app through its accessibility surface, nothing else.

<rule_1>
**XCUITEST, NOT SWIFT TESTING** — `import XCTest`; subclass `HealthTrackerUITestCase`; name cases `func testSubjectExpectation()` with `XCTAssert` checks. No `@testable import` — reach the app only through `app` and accessibility identifiers, never its internal types.
</rule_1>

<rule_2>
**TARGET BY IDENTIFIER, ASSERT BY LABEL** — locate elements with `AccessibilityID` identifiers; assert on visible content via `element.label.contains(...)`. Alert buttons and menu picker options surface no identifier, so select and assert those through `EnglishLabel`. Both files are hand-mirrored — when the app adds or renames an identifier, update `AccessibilityID`; when a user-facing string changes, update `EnglishLabel` to match `en.lproj/Localizable.strings`.
</rule_2>

<rule_3>
**WAIT, NEVER SLEEP** — selection, sheet dismissal, and swipe-action reveal all lag the action that triggers them. Gate the next step on `assertExists` / `assertNotExists` / `assertSelected`, which poll to a timeout. Never assert immediately after a tap and never insert a fixed delay.
</rule_3>

<rule_4>
**SCROLL BEFORE YOU TAP** — SwiftUI `List` rows and pickers below the fold may not exist yet, and controls pushed past the sheet's bottom edge report hittable while taps land dead. `scrollTo` (or swipe the list) the target into view first; reveal card swipe actions through `tapSwipeAction`, which falls back to the visible label when the identifier is not surfaced by the swipe host. The `CalendarStrip` is a horizontally *paged* week view (weeks start Monday) whose scroll position is **not** guaranteed to sit on today's week — it can reset to an adjacent week on re-layout (after a modal, or racing the launch scroll), and a day on another page reports an off-screen or clipped frame, so never blindly `.tap()` a day cell (that records `"Activation point invalid…"`). Reach a day by swiping its `calendarStrip` container until the cell is hittable, probing the cell each step rather than assuming which week shows (see `CalendarUITests.revealDayCell`): a clipped cell is nudged toward the edge it hangs off; a not-yet-rendered one is chased in its calendar direction (future right, past left).
</rule_4>

<rule_5>
**COMPOSE FLOWS FROM HELPERS** — build a scenario from the base-class flow helpers rather than re-scripting the modal tap-by-tap; a new flow that repeats across suites earns a helper on `HealthTrackerUITestCase`. UI tests are slow — each launches the app — so cover whole user journeys here and leave branch-level logic to `HealthTrackerTests`. Adding a feature or fixing a bug ends green; see the root **Workflow** for the red → green loop and the UI-test commands.
</rule_5>
