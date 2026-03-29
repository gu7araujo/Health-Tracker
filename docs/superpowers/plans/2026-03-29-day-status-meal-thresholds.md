# Day Status Meal Thresholds & Priority Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update meal thresholds for moderate (1→2 medium) and poor (2+→3+ medium) statuses, and fix evaluation priority so that any poor signal always wins — poor is checked first, before optimal and moderate.

**Architecture:** All logic lives in `DayData.swift`. The status computed property evaluates criteria in a fixed priority order — fixing priority is a 2-line swap. Threshold changes are each single-line changes in private computed properties. Localization strings and test fixtures must be updated to match.

**Tech Stack:** Swift, Swift Testing (`#expect`), NSLocalizedString, xcodebuild.

---

## New Logic Reference

| Priority | Status | Meal criterion | Other criteria |
|----------|--------|---------------|----------------|
| 1st — any signal wins | Poor (red) | **3+ medium OR any large** | Water <1.0L OR mood sad |
| 2nd — all must be true | Optimal (green) | ≤1 medium, no large, rest small/verySmall | Water ≥1.8L, workout ≥30min, mood good |
| 3rd — any signal | Moderate (yellow) | **exactly 2 medium** | Water 1.0–1.7L OR workout <30min OR mood neutral |

Priority order: `poor → optimal → moderate`. Poor is evaluated **first** — any poor signal overrides everything else, including what would otherwise be a perfect day.

---

## Files Modified

- **Modify:** `HealthTracker/Domain/Entities/DayData.swift` — criteria thresholds, evaluation order, explanation logic
- **Modify:** `HealthTracker/Domain/Entities/DayStatus.swift` — update case documentation comments
- **Modify:** `HealthTracker/Resources/en.lproj/Localizable.strings` — replace `meals_one_medium` with `meals_two_medium`
- **Modify:** `HealthTracker/Resources/pt-BR.lproj/Localizable.strings` — replace `meals_one_medium` with `meals_two_medium`
- **Modify:** `HealthTrackerTests/TestHelpers/TestDataBuilder.swift` — update `makeModerateDay` and `makePoorDay` builders
- **Modify:** `HealthTrackerTests/Domain/Entities/DayDataTests.swift` — update existing test, add new tests

---

### Task 1: Write failing tests for new thresholds and priority

**Files:**
- Modify: `HealthTrackerTests/Domain/Entities/DayDataTests.swift`

- [ ] **Step 1: Add test — 2 medium meals = moderate**

In `DayDataTests.swift`, add this test inside the `// MARK: - Status Computation Tests` section, after `status_isNotOptimal_withTwoMediumMeals`:

```swift
@Test("Two medium meals trigger moderate status")
func status_isModerate_withTwoMediumMeals() {
    var dayData = DayData(date: TestDataBuilder.fixedDate)
    dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .fifty))
    dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .fifty))
    dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
    dayData.water = 2.0
    dayData.mood = .good

    #expect(dayData.status == .moderate)
}
```

- [ ] **Step 2: Add test — 3 medium meals = poor**

Add after the test above:

```swift
@Test("Three or more medium meals trigger poor status")
func status_isPoor_withThreeOrMoreMediumMeals() {
    var dayData = DayData(date: TestDataBuilder.fixedDate)
    dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .fifty))
    dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .fifty))
    dayData.addMeal(Meal(description: "Dinner", quantity: .medium, satisfaction: .fifty))
    dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
    dayData.water = 2.0
    dayData.mood = .good

    #expect(dayData.status == .poor)
}
```

- [ ] **Step 3: Add test — priority: poor wins over moderate when both signals present**

Add after the test above:

```swift
@Test("Poor status takes priority over moderate when both signals are present")
func status_isPoor_prioritizedOverModerate() {
    // 2 medium meals (moderate meal signal) + low water (poor signal)
    var dayData = DayData(date: TestDataBuilder.fixedDate)
    dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .fifty))
    dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .fifty))
    dayData.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))
    dayData.water = 0.5
    dayData.mood = .good

    #expect(dayData.status == .poor)
}
```

- [ ] **Step 4: Update `status_isPoor_regardlessOfWorkouts` to use 3 medium meals**

Find the test at line ~229 and replace its body:

Old:
```swift
@Test("Poor status ignores workout duration")
func status_isPoor_regardlessOfWorkouts() {
    var dayData = DayData(date: TestDataBuilder.fixedDate)
    dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .hundred))
    dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .hundred))
    dayData.addWorkout(Workout(description: "Long run", duration: Workout.Duration(minutes: 120))) // Even with long workout
    dayData.water = 2.0
    dayData.mood = .good

    #expect(dayData.status == .poor) // Poor due to 2+ medium meals
}
```

New:
```swift
@Test("Poor status ignores workout duration")
func status_isPoor_regardlessOfWorkouts() {
    var dayData = DayData(date: TestDataBuilder.fixedDate)
    dayData.addMeal(Meal(description: "Breakfast", quantity: .medium, satisfaction: .hundred))
    dayData.addMeal(Meal(description: "Lunch", quantity: .medium, satisfaction: .hundred))
    dayData.addMeal(Meal(description: "Dinner", quantity: .medium, satisfaction: .hundred))
    dayData.addWorkout(Workout(description: "Long run", duration: Workout.Duration(minutes: 120))) // Even with long workout
    dayData.water = 2.0
    dayData.mood = .good

    #expect(dayData.status == .poor) // Poor due to 3+ medium meals
}
```

- [ ] **Step 5: Run tests to confirm `status_isModerate_withTwoMediumMeals` fails**

```bash
xcodebuild test \
  -project HealthTracker.xcodeproj \
  -scheme HealthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:HealthTrackerTests/DayDataTests \
  2>&1 | grep -E "FAIL|PASS|error:|status_isModerate"
```

Expected: `status_isModerate_withTwoMediumMeals` → **FAIL** (currently 2 medium = poor). All other new/updated tests → PASS.

---

### Task 2: Update meal thresholds and fix evaluation priority

**Files:**
- Modify: `HealthTracker/Domain/Entities/DayData.swift`

- [ ] **Step 1: Fix evaluation order in `status` computed property**

In `DayData.swift` at the `status` computed property (~line 70), swap the order of poor and moderate checks:

Old:
```swift
// 2-4 categories have data: evaluate status
if meetsOptimalCriteria { return .optimal }

if meetsModerateCriteria { return .moderate }

if meetsPoorCriteria { return .poor }

// Fallback: has data but doesn't meet any specific criteria
return .poor
```

New:
```swift
// 2-4 categories have data: evaluate status
// Poor is checked first — any poor signal always wins
if meetsPoorCriteria { return .poor }

if meetsOptimalCriteria { return .optimal }

if meetsModerateCriteria { return .moderate }

// Fallback: has data but doesn't meet any specific criteria
return .poor
```

- [ ] **Step 2: Update `meetsModerateCriteria` meal threshold**

In `meetsModerateCriteria` (~line 200), change:

Old:
```swift
let hasModerateMeals = mediumMealCount == 1
```

New:
```swift
let hasModerateMeals = mediumMealCount == 2
```

Also update the comment above the property:

Old:
```swift
/// Checks if any moderate (yellow) criteria are met.
/// Requirements (ANY one of):
/// - Meals: Exactly 1 medium meal (satiety ignored)
```

New:
```swift
/// Checks if any moderate (yellow) criteria are met.
/// Requirements (ANY one of):
/// - Meals: Exactly 2 medium meals (satiety ignored)
```

- [ ] **Step 3: Update `meetsPoorCriteria` meal threshold**

In `meetsPoorCriteria` (~line 220), change:

Old:
```swift
let poorMeals = mediumMealCount >= 2 || hasLargeMeal
```

New:
```swift
let poorMeals = mediumMealCount >= 3 || hasLargeMeal
```

Also update the comment above the property:

Old:
```swift
/// Checks if any poor (red) criteria are met.
/// Requirements (ANY one of):
/// - Meals: 2+ medium meals OR any large meal (satiety ignored)
```

New:
```swift
/// Checks if any poor (red) criteria are met.
/// Requirements (ANY one of):
/// - Meals: 3+ medium meals OR any large meal (satiety ignored)
```

- [ ] **Step 4: Run all DayData tests**

```bash
xcodebuild test \
  -project HealthTracker.xcodeproj \
  -scheme HealthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:HealthTrackerTests/DayDataTests \
  2>&1 | grep -E "FAIL|PASS|error:" | tail -20
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add HealthTracker/Domain/Entities/DayData.swift HealthTrackerTests/Domain/Entities/DayDataTests.swift
git commit -m "feat: update meal thresholds (moderate: 2 medium, poor: 3+ medium) and fix priority order"
```

---

### Task 3: Update `statusExplanation` and localization strings

**Files:**
- Modify: `HealthTracker/Domain/Entities/DayData.swift`
- Modify: `HealthTracker/Resources/en.lproj/Localizable.strings`
- Modify: `HealthTracker/Resources/pt-BR.lproj/Localizable.strings`

- [ ] **Step 1: Replace `meals_one_medium` with `meals_two_medium` in EN strings**

In `HealthTracker/Resources/en.lproj/Localizable.strings`, replace line 159:

Old:
```
"day_status_reason.meals_one_medium" = "1 medium meal";
```

New:
```
"day_status_reason.meals_two_medium" = "2 medium meals";
```

- [ ] **Step 2: Replace `meals_one_medium` with `meals_two_medium` in PT-BR strings**

In `HealthTracker/Resources/pt-BR.lproj/Localizable.strings`, replace line 159:

Old:
```
"day_status_reason.meals_one_medium" = "1 refeição média";
```

New:
```
"day_status_reason.meals_two_medium" = "2 refeições médias";
```

- [ ] **Step 3: Update `statusExplanation` meal reason logic**

In `DayData.swift`, in the `statusExplanation` computed property (~line 109), replace the meals reason block:

Old:
```swift
// Check meal issues
let mediumMealCount = meals.filter { $0.quantity == .medium }.count
let hasLargeMeal = meals.contains { $0.quantity == .large }

if mediumMealCount >= 2 || hasLargeMeal {
    reasons.append(NSLocalizedString("day_status_reason.meals_multiple_medium", comment: ""))
} else if mediumMealCount == 1 {
    reasons.append(NSLocalizedString("day_status_reason.meals_one_medium", comment: ""))
}
```

New:
```swift
// Check meal issues
let mediumMealCount = meals.filter { $0.quantity == .medium }.count
let hasLargeMeal = meals.contains { $0.quantity == .large }

if mediumMealCount >= 3 || hasLargeMeal {
    reasons.append(NSLocalizedString("day_status_reason.meals_multiple_medium", comment: ""))
} else if mediumMealCount == 2 {
    reasons.append(NSLocalizedString("day_status_reason.meals_two_medium", comment: ""))
}
```

- [ ] **Step 4: Run all tests**

```bash
xcodebuild test \
  -project HealthTracker.xcodeproj \
  -scheme HealthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "FAIL|error:" | tail -20
```

Expected: No failures.

- [ ] **Step 5: Commit**

```bash
git add \
  HealthTracker/Domain/Entities/DayData.swift \
  HealthTracker/Resources/en.lproj/Localizable.strings \
  HealthTracker/Resources/pt-BR.lproj/Localizable.strings
git commit -m "feat: update statusExplanation and localization for new meal thresholds"
```

---

### Task 4: Update test builders and DayStatus.swift documentation

**Files:**
- Modify: `HealthTrackerTests/TestHelpers/TestDataBuilder.swift`
- Modify: `HealthTracker/Domain/Entities/DayStatus.swift`

- [ ] **Step 1: Update `makeModerateDay` to use 2 medium meals**

In `TestDataBuilder.swift`, replace `makeModerateDay`:

Old:
```swift
/// Creates a moderate day (should result in `.moderate` status).
/// - Meals: 1 medium (triggers moderate when other optimal criteria not fully met)
/// - Water: 1.5L (moderate range)
/// - Workout: 15 min (< 30 min, triggers moderate)
/// - Mood: Neutral
@MainActor
static func makeModerateDay(date: Date = fixedDate) -> DayData {
    makeDayData(
        date: date,
        meals: [
            Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty)
        ],
        workouts: [Workout(description: "Light workout", duration: Workout.Duration(minutes: 15))],
        water: 1.5,
        mood: .neutral
    )
}
```

New:
```swift
/// Creates a moderate day (should result in `.moderate` status).
/// - Meals: 2 medium (triggers moderate)
/// - Water: 1.5L (moderate range)
/// - Workout: 15 min (< 30 min, triggers moderate)
/// - Mood: Neutral
@MainActor
static func makeModerateDay(date: Date = fixedDate) -> DayData {
    makeDayData(
        date: date,
        meals: [
            Meal(description: "Lunch", quantity: .medium, satisfaction: .eighty),
            Meal(description: "Dinner", quantity: .medium, satisfaction: .eighty)
        ],
        workouts: [Workout(description: "Light workout", duration: Workout.Duration(minutes: 15))],
        water: 1.5,
        mood: .neutral
    )
}
```

- [ ] **Step 2: Update `makePoorDay` to use 3 medium meals**

In `TestDataBuilder.swift`, replace `makePoorDay`:

Old:
```swift
/// Creates a poor day (should result in `.poor` status).
/// - Meals: 2 medium (2+ medium meals triggers poor)
/// - Water: 0.5L (< 1.0L triggers poor)
/// - Workout: 30 min (workouts don't affect poor status)
/// - Mood: Sad
@MainActor
static func makePoorDay(date: Date = fixedDate) -> DayData {
    makeDayData(
        date: date,
        meals: [
            Meal(description: "Breakfast", quantity: .medium, satisfaction: .hundred),
            Meal(description: "Lunch", quantity: .medium, satisfaction: .hundred)
        ],
        workouts: [Workout(description: "Walk", duration: Workout.Duration(minutes: 30))],
        water: 0.5,
        mood: .sad
    )
}
```

New:
```swift
/// Creates a poor day (should result in `.poor` status).
/// - Meals: 3 medium (3+ medium meals triggers poor)
/// - Water: 0.5L (< 1.0L triggers poor)
/// - Workout: 30 min (workouts don't affect poor status)
/// - Mood: Sad
@MainActor
static func makePoorDay(date: Date = fixedDate) -> DayData {
    makeDayData(
        date: date,
        meals: [
            Meal(description: "Breakfast", quantity: .medium, satisfaction: .hundred),
            Meal(description: "Lunch", quantity: .medium, satisfaction: .hundred),
            Meal(description: "Dinner", quantity: .medium, satisfaction: .hundred)
        ],
        workouts: [Workout(description: "Walk", duration: Workout.Duration(minutes: 30))],
        water: 0.5,
        mood: .sad
    )
}
```

- [ ] **Step 3: Update `DayStatus.swift` case documentation comments**

In `DayStatus.swift`, replace the `moderate` and `poor` case doc comments:

Old:
```swift
/// Moderate conditions (ANY one of):
/// - Meals: Exactly 1 medium meal
/// - Water: 1.0-1.7L
/// - Workouts: < 30 minutes total
/// - Mood: neutral
case moderate

/// Poor conditions (ANY one of):
/// - Meals: 2+ medium meals OR any large meal
/// - Water: < 1.0L
/// - Mood: sad
case poor
```

New:
```swift
/// Moderate conditions (ANY one of):
/// - Meals: Exactly 2 medium meals
/// - Water: 1.0-1.7L
/// - Workouts: < 30 minutes total
/// - Mood: neutral
case moderate

/// Poor conditions (ANY one of):
/// - Meals: 3+ medium meals OR any large meal
/// - Water: < 1.0L
/// - Mood: sad
case poor
```

- [ ] **Step 4: Run all tests**

```bash
xcodebuild test \
  -project HealthTracker.xcodeproj \
  -scheme HealthTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "FAIL|error:" | tail -20
```

Expected: No failures.

- [ ] **Step 5: Commit**

```bash
git add \
  HealthTrackerTests/TestHelpers/TestDataBuilder.swift \
  HealthTracker/Domain/Entities/DayStatus.swift
git commit -m "chore: update test builders and DayStatus docs for new meal thresholds"
```
