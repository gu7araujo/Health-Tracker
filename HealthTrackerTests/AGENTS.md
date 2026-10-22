# Test Suite

The unit-test target. Built on **Swift Testing** (not XCTest), it mirrors the production tree one-to-one: one test struct per type, grouped under `Domain/`, `Data/`, and `Presentation/`. Every test runs against protocol fakes and deterministic fixtures — no real services, files, or wall clock. UI flows live in the separate `HealthTrackerUITests` target.

## Fixtures & Mocks

The two pieces of shared machinery every test leans on:

- **`TestDataBuilder`** — `fixedDate`/`fixedDatePlusOne` anchor time, and `makeOptimalDay`/`makeModerateDay`/`makePoorDay`/`makeIncompleteDay`/`makeEmptyDay` build a `DayData` that lands in each status tier, with `makeRecorded…` wrappers for the `RecordedDayData` the repository speaks. Only the factory methods are `@MainActor` (see rule_2).
- **`Mocks/`** — each mock backs a domain protocol and exposes two knobs: `...Result` properties to stub return values, and `...Called` / `...CalledWith` properties to verify interactions. Stub before acting, assert the flags after.

## Rules

Deterministic and isolated — every test is fast, repeatable, and free of real I/O.

<rule_1>
**SWIFT TESTING, NOT XCTEST** — `import Testing`; `@Test` functions with `#expect` / `#require` assertions, and `@Test(arguments:)` for table-driven cases (see `MoodTests`). `@testable import HealthTracker` for internal access. `await` async code directly — there is no `XCTestExpectation`. Enforced by SwiftLint rule `unit_tests_use_swift_testing`.
</rule_1>

<rule_2>
**@MainActor ISOLATION** — mark each test struct `@MainActor`; the `@Observable` types it exercises require it. In helpers, isolate only the factory methods that build `@Observable`/`@MainActor` types — never the whole `enum`/`struct` — so non-isolated constants like `TestDataBuilder.fixedDate` stay reachable from any context.
</rule_2>

<rule_3>
**FAKES & FIXTURES, NEVER REAL SERVICES** — drive code under test through the `Mocks/` protocol doubles and build inputs with `TestDataBuilder`; never touch real `UserDefaults`, files, or notification APIs. Fixed dates keep results deterministic; one behaviour per test, named `subject_expectation` (e.g. `loadData_createsEmptyDayForSelectedDate`); keep each under ~1s.
</rule_3>

<rule_4>
**ASSERT ON KEYS, NOT TRANSLATIONS** — compare localized output against the localization key, so tests hold under any locale.

```swift
// ✅ locale-independent
let expected = NSLocalizedString("mood_good", comment: "")
#expect(mood.localizedName == expected)

// ❌ breaks outside pt-BR
#expect(mood.localizedName == "Bom")
```
</rule_4>

<rule_5>
**WHAT-TO-COVER LIVES WITH THE LAYER** — this suite is the *how*; the per-layer *what* is owned by each layer's `AGENTS.md` (`Domain`, `Data`, `Presentation`). Coverage bars live in `scripts/quality-thresholds.env`, enforced by `scripts/quality`. Adding a feature or fixing a bug ends green — see the root **Workflow** for the red → green loop and the test commands.
</rule_5>
