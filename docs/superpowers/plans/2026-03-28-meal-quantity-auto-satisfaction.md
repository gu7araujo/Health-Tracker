# Meal Quantity Auto-Satisfaction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the user changes the quantity picker in `AddEditModal` (meal section), automatically update the satisfaction picker to a mapped default — unless the user has manually changed the satisfaction first.

**Architecture:** Add a `onChange(of: selectedQuantity)` modifier to the `mealFields` picker. A separate `@State var satisfactionWasManuallySet: Bool` flag tracks whether the user touched satisfaction directly. When quantity changes, only auto-update satisfaction if that flag is `false`. The mapping is: `verySmall/small → .thirty`, `medium → .fifty`, `large → .hundred`. When the user changes satisfaction manually, the flag is set to `true` and auto-updates stop for the rest of that session.

**Tech Stack:** SwiftUI, Swift Testing (`@testable import HealthTracker`)

---

### Task 1: Add `Meal.Quantity` → `Meal.Satisfaction` default mapping

**Files:**
- Modify: `HealthTracker/Domain/Entities/Meal.swift`
- Test: `HealthTrackerTests/Domain/Entities/MealTests.swift`

- [ ] **Step 1: Write the failing test**

Open `HealthTrackerTests/Domain/Entities/MealTests.swift` and add a new test section at the end of the file:

```swift
// MARK: - Quantity Default Satisfaction Tests

@Test(arguments: [
    (Meal.Quantity.verySmall, Meal.Satisfaction.thirty),
    (.small, Meal.Satisfaction.thirty),
    (.medium, Meal.Satisfaction.fifty),
    (.large, Meal.Satisfaction.hundred)
])
func quantity_defaultSatisfaction(quantity: Meal.Quantity, expectedSatisfaction: Meal.Satisfaction) {
    #expect(quantity.defaultSatisfaction == expectedSatisfaction)
}
```

- [ ] **Step 2: Run test to verify it fails**

In Xcode, run `MealTests/quantity_defaultSatisfaction` via Product > Test.
Expected: compile error — `'Meal.Quantity' has no member 'defaultSatisfaction'`.

- [ ] **Step 3: Add `defaultSatisfaction` to `Meal.Quantity`**

In `HealthTracker/Domain/Entities/Meal.swift`, inside the `Quantity` enum, add after `var localizedName`:

```swift
var defaultSatisfaction: Satisfaction {
    switch self {
    case .verySmall, .small: .thirty
    case .medium: .fifty
    case .large: .hundred
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run `MealTests/quantity_defaultSatisfaction`.
Expected: PASS (4 parameterized cases).

- [ ] **Step 5: Commit**

```bash
git add HealthTracker/Domain/Entities/Meal.swift HealthTrackerTests/Domain/Entities/MealTests.swift
git commit -m "feat: add defaultSatisfaction mapping to Meal.Quantity"
```

---

### Task 2: Wire auto-update in `AddEditModal`

**Files:**
- Modify: `HealthTracker/Presentation/Views/AddEditModal.swift`

> Note: `AddEditModal` is a pure SwiftUI view — the logic is simple enough to live here. No ViewModel change is needed.

- [ ] **Step 1: Add `satisfactionWasManuallySet` state flag**

In `AddEditModal.swift`, after the existing `@State` declarations (around line 21), add:

```swift
@State private var satisfactionWasManuallySet: Bool = false
```

- [ ] **Step 2: Mark manual satisfaction changes**

In `mealFields`, the satisfaction `Picker` currently has no `onChange`. Replace the satisfaction `Picker` with a version that sets the flag:

```swift
Picker(String(localized: "satisfaction_picker_label"), selection: $selectedSatisfaction) {
    ForEach(Meal.Satisfaction.allCases, id: \.self) { satisfaction in
        Text(satisfaction.localizedName).tag(satisfaction)
    }
}
.onChange(of: selectedSatisfaction) {
    satisfactionWasManuallySet = true
}
```

- [ ] **Step 3: Auto-update satisfaction when quantity changes**

In `mealFields`, the quantity `Picker` currently has no `onChange`. Replace it with:

```swift
Picker(String(localized: "quantity_picker_label"), selection: $selectedQuantity) {
    ForEach(Meal.Quantity.allCases, id: \.self) { quantity in
        Text(quantity.localizedName).tag(quantity)
    }
}
.onChange(of: selectedQuantity) { _, newQuantity in
    if !satisfactionWasManuallySet {
        selectedSatisfaction = newQuantity.defaultSatisfaction
    }
}
```

- [ ] **Step 4: Reset `satisfactionWasManuallySet` when loading existing data**

When editing an existing meal, `loadExistingData()` sets both `selectedQuantity` and `selectedSatisfaction` from saved data. The `onChange` for `selectedSatisfaction` would fire during load and incorrectly set the flag to `true`, disabling auto-update permanently. Fix this by resetting the flag after loading:

In `loadExistingData()`, after setting `selectedSatisfaction`, add:

```swift
private func loadExistingData() {
    if section == .meal, let mealId, let meal = viewModel.meal(withId: mealId) {
        text = meal.description
        selectedQuantity = meal.quantity
        selectedSatisfaction = meal.satisfaction
        satisfactionWasManuallySet = false
    } else if section == .workout, let workoutId, let workout = viewModel.workout(withId: workoutId) {
        text = workout.description
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = workout.duration.minutes / 60
        components.minute = workout.duration.minutes % 60
        selectedDuration = calendar.date(from: components) ?? Date()
    }
}
```

> Note: `satisfactionWasManuallySet` is already `false` by default for new meals — no extra handling needed there.

- [ ] **Step 5: Build to verify no compile errors**

In Xcode, press ⌘B.
Expected: Build succeeds with no errors or warnings.

- [ ] **Step 6: Commit**

```bash
git add HealthTracker/Presentation/Views/AddEditModal.swift
git commit -m "feat: auto-update satisfaction when quantity changes in AddEditModal"
```

---

## Self-Review

**Spec coverage:**
| Requirement | Covered by |
|---|---|
| Starts with Small + 50% selected | Existing defaults unchanged (`selectedQuantity = .small`, `selectedSatisfaction = .fifty`) |
| verySmall/small → 30% | `defaultSatisfaction` mapping + `onChange` in Task 2 |
| medium → 50% | `defaultSatisfaction` mapping + `onChange` in Task 2 |
| large → 100% | `defaultSatisfaction` mapping + `onChange` in Task 2 |
| Manual satisfaction change disables auto-update | `satisfactionWasManuallySet` flag set on `onChange(of: selectedSatisfaction)` |
| Auto-update only fires for quantity changes | Flag check in `onChange(of: selectedQuantity)` |
| Edit mode loads correctly without breaking flag | `satisfactionWasManuallySet = false` reset in `loadExistingData()` |

**Placeholder scan:** None found.

**Type consistency:** `Meal.Satisfaction.thirty`, `.fifty`, `.hundred` used consistently. `defaultSatisfaction` defined in Task 1 and consumed in Task 2.
