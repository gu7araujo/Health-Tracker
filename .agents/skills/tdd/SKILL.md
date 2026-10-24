---
name: tdd
description: Test-driven development, the red → green loop. Use when writing or changing production code (a feature or a bug fix) or when asked to work test-first.
---

# Test-Driven Development

TDD is the red → green loop from the root `AGENTS.md` **Workflow**. This skill is the reference that makes each cycle produce tests worth keeping. Every section applies on every cycle; consult it before and during the loop. The test suite's mechanics (Swift Testing, `Mocks/` knobs, `TestDataBuilder`, `subject_expectation` names, `@MainActor`) live in `HealthTrackerTests/AGENTS.md`; follow them.

## Rules of the loop

- **Red before green.** Write the test, run it, and watch it fail for the reason you expect. Then write only enough code to pass it. A bug fix starts red: a regression test that reproduces the bug.
- **One slice at a time.** One behaviour, one test, one minimal implementation per cycle. Each test is a **tracer bullet** through the real path, so the next cycle responds to what this one taught you.
- **Green ends the cycle.** Cleanup is a separate step after green (the `simplify` skill), with the tests already guarding it.

## What a good test is

A good test exercises a type's **public interface** (what callers use, reached through `@testable import`) and states a behaviour as a specification: `status_isIncomplete_whenOnlyOneCategoryFilled` says what capability exists. It survives refactors because it never depends on internal structure.

```swift
@Test func updateWater_zeroRemovesWater() {
    let (viewModel, mockRepository) = createViewModel()
    mockRepository.loadAllDaysResult = []
    viewModel.loadData()
    viewModel.selectedDate = TestDataBuilder.fixedDate

    viewModel.updateWater(2.0)
    viewModel.updateWater(0)

    #expect(viewModel.currentDayData?.water == nil)
}
```

Asserting a mock's `...Called` / `...CalledWith` flag is behaviour when the interaction is the contract: `SaveDayDataUseCase` exists to hand days to the repository, so `mockRepository.saveCalledWithDays` is its observable output.

## Anti-patterns

- **Implementation-coupled**: the test reaches past the interface, such as widening `DayData.meetsPoorCriteria` from `private` so a test can call it, instead of asserting `status`. The tell: a refactor that keeps behaviour breaks the test.
- **Tautological**: the expected value is recomputed the way the code computes it, so the test passes by construction and can never disagree with the code. Expected values come from an independent source: a literal, a worked example, the spec.

  ```swift
  var day = DayData(date: TestDataBuilder.fixedDate)
  day.water = 1.5

  // Tautological: rebuilds the status rule
  let filled = [!day.meals.isEmpty, day.water != nil, !day.workouts.isEmpty, day.mood != nil]
      .filter { $0 }.count
  #expect(day.status == (filled < 2 ? .incomplete : .poor))

  // Independent literal
  #expect(day.status == .incomplete)
  ```

- **Horizontal slicing**: writing every test first, then every implementation. Bulk tests verify _imagined_ behaviour, lock in a test structure before the implementation is understood, and stay green through real changes. Work in **vertical slices**: one test, one implementation, repeat.
