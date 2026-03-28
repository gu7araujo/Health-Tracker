# Default Satisfaction Mapping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update `Meal.Quantity.defaultSatisfaction` so each quantity maps to a new satisfaction value: verySmall → 30%, small → 50%, medium → 80%, large → 100%.

**Architecture:** Single-property change in `Meal.Quantity.defaultSatisfaction` plus a corresponding test update. The comment about `.eighty` being manually-only must also be removed since it is now reachable as a default.

**Tech Stack:** Swift, Swift Testing framework

---

### Task 1: Update the failing test first (TDD)

**Files:**
- Modify: `HealthTrackerTests/Domain/Entities/MealTests.swift:170-178`

- [ ] **Step 1: Update the test to reflect the new mapping**

Replace the arguments in `quantity_defaultSatisfaction` (lines 170–178):

```swift
@Test(arguments: [
    (Meal.Quantity.verySmall, Meal.Satisfaction.thirty),
    (.small, Meal.Satisfaction.fifty),
    (.medium, Meal.Satisfaction.eighty),
    (.large, Meal.Satisfaction.hundred)
])
func quantity_defaultSatisfaction(quantity: Meal.Quantity, expectedSatisfaction: Meal.Satisfaction) {
    #expect(quantity.defaultSatisfaction == expectedSatisfaction)
}
```

- [ ] **Step 2: Run the test to verify it fails**

In Xcode, run `MealTests/quantity_defaultSatisfaction` (Product → Test or ⌘U filtered to this test).

Expected: `.small` case fails — actual `.thirty`, expected `.fifty`.

---

### Task 2: Update the implementation

**Files:**
- Modify: `HealthTracker/Domain/Entities/Meal.swift:29-36`

- [ ] **Step 1: Update `defaultSatisfaction` and remove stale comment**

Replace lines 29–36:

```swift
var defaultSatisfaction: Satisfaction {
    switch self {
    case .verySmall: .thirty
    case .small: .fifty
    case .medium: .eighty
    case .large: .hundred
    }
}
```

The previous comment `// .eighty is intentionally omitted — it is only reachable via manual user selection.` must be deleted; `.eighty` is now a valid default for `.medium`.

- [ ] **Step 2: Run all tests to verify everything passes**

Run the full test suite (⌘U).

Expected: All tests pass, including `quantity_defaultSatisfaction`.

- [ ] **Step 3: Commit**

```bash
git add HealthTracker/Domain/Entities/Meal.swift HealthTrackerTests/Domain/Entities/MealTests.swift
git commit -m "feat: update default satisfaction mapping (verySmall→30%, small→50%, medium→80%, large→100%)"
```
