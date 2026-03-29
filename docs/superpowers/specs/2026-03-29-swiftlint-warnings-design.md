# SwiftLint Warnings Fix — Design Spec

**Date:** 2026-03-29
**Scope:** Fix all 22 SwiftLint warnings across 10 files
**Strategy:** Batch by violation type (Approach A)

---

## Overview

Three ordered batches, each focused on a single category of change. Batches are independent and can each be committed separately.

---

## Batch 1 — Quick Fixes (`line_length`, `for_where`, `type_name`)

No logic changes. Purely mechanical.

### `line_length` violations (13 total)

Wrap long lines using one of:
- Break `String(format:...)` arguments to the next line
- Extract a long string literal into a local `let` before use
- Split chained calls / long string interpolations across lines

| File | Line | Current length | Fix |
|------|------|----------------|-----|
| `CalculateAnalyticsUseCase.swift` | 38 | 142 | Split `logger.info` interpolation |
| `ScheduleNotificationsUseCase.swift` | 119 | 121 | Wrap condition to next line |
| `AddEditModal.swift` | 81 | 148 | Extract placeholder `String(localized:)` to local `let` |
| `MainView.swift` | 163 | 126 | Break `String(format:...)` arguments |
| `MainView.swift` | 288 | 125 | Break `String(format:...)` arguments |
| `AnalyticsView.swift` | 94 | 121 | Break `String(format:...)` arguments |
| `AnalyticsView.swift` | 124 | 139 | Break `String(format:...)` arguments |
| `AnalyticsView.swift` | 126 | 125 | Break `String(format:...)` arguments |
| `AnalyticsView.swift` | 155 | 125 | Break `String(format:...)` arguments |
| `AnalyticsView.swift` | 158 | 125 | Break `String(format:...)` arguments |
| `AnalyticsView.swift` | 215 | 127 | Break `String(format:...)` arguments |
| `ScheduleNotificationsUseCaseTests.swift` | 109 | 121 | Wrap assertion |
| `MainViewModelTests.swift` | 25 | 133 | Break multi-member return type across lines |
| `DayDataTests.swift` | 273 | 128 | Wrap assertion |

### `for_where` violation (1 total)

**File:** `DataMigration.swift:77`

**Before:**
```swift
for workout in recordedDay.dayData.workouts {
    if [10, 15, 30, 40, 60, 90, 120].contains(workout.duration.minutes) {
        ...
    }
}
```

**After:**
```swift
for workout in recordedDay.dayData.workouts
    where [10, 15, 30, 40, 60, 90, 120].contains(workout.duration.minutes) {
    ...
}
```

### `type_name` violation (1 total)

**File:** `RequestNotificationPermissionUseCaseTests.swift:13`

Rename `RequestNotificationPermissionUseCaseTests` (41 chars) → `RequestNotifPermissionUseCaseTests` (35 chars).

---

## Batch 2 — Struct Extractions (`large_tuple`, `file_length`)

### `large_tuple` violations (2 total)

**`MoodBarChart.swift:15`** — Replace `(mood: Mood, count: Int, color: Color)` with:
```swift
private struct MoodChartItem {
    let mood: Mood
    let count: Int
    let color: Color
}
```
Defined at the bottom of `MoodBarChart.swift`. Update `chartData` property type and usage throughout.

**`OverallHealthRingChart.swift:15`** — Replace `(status: DayStatus, count: Int, color: Color)` with:
```swift
private struct StatusChartItem {
    let status: DayStatus
    let count: Int
    let color: Color
}
```
Defined at the bottom of `OverallHealthRingChart.swift`. Update `chartData` property type and usage throughout.

### `file_length` violation (1 total)

**File:** `MainView.swift` (410 lines, limit 400)

The file already contains well-defined private section structs. Move each to its own file, changing `private struct` → `struct` (internal):

| Type | Destination |
|------|-------------|
| `MealsSectionView` | `Presentation/Views/MealsSectionView.swift` |
| `WaterSectionView` | `Presentation/Views/WaterSectionView.swift` |
| `WorkoutsSectionView` | `Presentation/Views/WorkoutsSectionView.swift` |
| `MoodSectionView` | `Presentation/Views/MoodSectionView.swift` |
| `EmptyListRow` | `Presentation/Views/Components/EmptyListRow.swift` |
| `UUID: Identifiable` extension | `Extensions/UUID+Identifiable.swift` |

After extraction, `MainView.swift` will contain only the `MainView` struct (~100 lines).

---

## Batch 3 — Structural Refactors (`type_body_length`, `function_body_length`)

### `CalculateAnalyticsUseCase.swift`

**Violations:** type body 280 lines (limit 250), function body 53 lines (limit 50)

Split private methods into extension files in the same `Domain/UseCases/` directory.

**`CalculateAnalyticsUseCase.swift`** — keeps only:
- Properties (`repository`, `logger`)
- `init`
- `execute(for:)` (~40 lines total)

**`CalculateAnalyticsUseCase+Meals.swift`** — `calculateMealAnalytics` refactored to call 3 extracted private helpers (bringing it under 50 lines):
- `buildQuantityDistribution(from meals: [Meal]) -> [Meal.Quantity: Int]`
- `buildDailyCounts(from days: [DayData]) -> [Date: Int]`
- `buildSatisfactionTrend(from days: [DayData]) -> [Date: [Meal.Satisfaction: Int]]`

**`CalculateAnalyticsUseCase+Water.swift`** — `calculateWaterAnalytics`

**`CalculateAnalyticsUseCase+Workout.swift`** — `calculateWorkoutAnalytics` + `calculateStreaks`

**`CalculateAnalyticsUseCase+Mood.swift`** — `calculateMoodAnalytics` + `calculateBestWorstWeeks`

**`CalculateAnalyticsUseCase+Overall.swift`** — `calculateOverallAnalytics`

### `MainViewModelTests.swift`

**Violations:** type body 254 lines (limit 250), one `line_length` (line 25 — fixed naturally by split)

Split into 4 separate `@MainActor struct` test types, each with its own `createViewModel()` helper copy. Delete `MainViewModelTests.swift` once all tests are migrated.

| New file | Tests |
|----------|-------|
| `MainViewModelLoadTests.swift` | Initialization, load data |
| `MainViewModelDateTests.swift` | Date selection, current day data |
| `MainViewModelWaterMoodTests.swift` | Water management, mood management |
| `MainViewModelMealWorkoutTests.swift` | Meal CRUD, workout CRUD, state consistency |

---

## Success Criteria

- Zero SwiftLint warnings after all three batches
- All existing tests pass
- No new files exceed SwiftLint limits
- Build succeeds
