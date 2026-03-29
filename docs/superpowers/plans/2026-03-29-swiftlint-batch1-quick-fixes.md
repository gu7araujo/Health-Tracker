# Batch 1: Quick Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 15 warnings — 13 `line_length`, 1 `for_where`, 1 `type_name` — with no logic changes.

**Architecture:** Mechanical line-wrapping and one `for`/`where` refactor. No new files, no logic changes.

**Tech Stack:** Swift 6, SwiftLint

---

## Task 1: Fix long lines in production code

**Files:**
- Modify: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift:38`
- Modify: `HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift:119`
- Modify: `HealthTracker/Data/Migration/DataMigration.swift:75–81`
- Modify: `HealthTracker/Presentation/Views/AddEditModal.swift:81`
- Modify: `HealthTracker/Presentation/Views/MainView.swift:163,288`
- Modify: `HealthTracker/Presentation/Views/AnalyticsView.swift:94,124,126,155,158,215`

- [ ] **Step 1: Fix `CalculateAnalyticsUseCase.swift:38`**

Replace:
```swift
        logger.info("Analytics calculated: \(analytics.mealAnalytics.totalMeals) meals, \(analytics.workoutAnalytics.totalWorkouts) workouts")
```
With:
```swift
        let meals = analytics.mealAnalytics.totalMeals
        let workouts = analytics.workoutAnalytics.totalWorkouts
        logger.info("Analytics calculated: \(meals) meals, \(workouts) workouts")
```

- [ ] **Step 2: Fix `ScheduleNotificationsUseCase.swift:119`**

Replace:
```swift
                let eveningComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: eveningDate)
```
With:
```swift
                let eveningComponents = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: eveningDate)
```

- [ ] **Step 3: Fix `DataMigration.swift:75–81` (`for_where`)**

Replace:
```swift
        for recordedDay in allRecordedDays {
            for workout in recordedDay.dayData.workouts {
                // These minute values indicate they were converted from old enum values
                if [10, 15, 30, 40, 60, 90, 120].contains(workout.duration.minutes) {
                    logger.debug("Loaded (auto-converted): '\(workout.description)' = \(workout.duration.minutes)min")
                    convertedCount += 1
                }
            }
        }
```
With:
```swift
        for recordedDay in allRecordedDays {
            for workout in recordedDay.dayData.workouts
                where [10, 15, 30, 40, 60, 90, 120].contains(workout.duration.minutes) {
                logger.debug("Loaded (auto-converted): '\(workout.description)' = \(workout.duration.minutes)min")
                convertedCount += 1
            }
        }
```

- [ ] **Step 4: Fix `AddEditModal.swift:81`**

Replace:
```swift
                    TextField(
                        section == .meal ? String(localized: "meal_description_placeholder") : String(localized: "workout_description_placeholder"),
                        text: $text
                    )
```
With:
```swift
                    TextField(
                        section == .meal
                            ? String(localized: "meal_description_placeholder")
                            : String(localized: "workout_description_placeholder"),
                        text: $text
                    )
```

- [ ] **Step 5: Fix `MainView.swift:163`**

Replace:
```swift
                                Text(String(format: String(localized: "quantity_label"), meal.quantity.localizedName))
```
With:
```swift
                                Text(String(
                                    format: String(localized: "quantity_label"),
                                    meal.quantity.localizedName))
```

- [ ] **Step 6: Fix `MainView.swift:288`**

Replace:
```swift
                                Text(String(format: String(localized: "workout_time_label"), workout.duration.localizedName))
```
With:
```swift
                                Text(String(
                                    format: String(localized: "workout_time_label"),
                                    workout.duration.localizedName))
```

- [ ] **Step 7: Fix `AnalyticsView.swift:94`**

Replace:
```swift
                        statItem(String(localized: "health_score"), value: String(format: "%.0f", analytics.healthScore))
```
With:
```swift
                        statItem(String(localized: "health_score"),
                                 value: String(format: "%.0f", analytics.healthScore))
```

- [ ] **Step 8: Fix `AnalyticsView.swift:124`**

Replace:
```swift
                        statItem(String(localized: "average_satisfaction"), value: String(format: "%.0f%%", analytics.averageSatisfaction))
```
With:
```swift
                        statItem(String(localized: "average_satisfaction"),
                                 value: String(format: "%.0f%%", analytics.averageSatisfaction))
```

- [ ] **Step 9: Fix `AnalyticsView.swift:126`**

Replace:
```swift
                        statItem(String(localized: "common_size"), value: mostCommonQuantity(analytics.quantityDistribution))
```
With:
```swift
                        statItem(String(localized: "common_size"),
                                 value: mostCommonQuantity(analytics.quantityDistribution))
```

- [ ] **Step 10: Fix `AnalyticsView.swift:155`**

Replace:
```swift
                        statItem(String(localized: "daily_average"), value: String(format: "%.1fL", analytics.averageIntake))
```
With:
```swift
                        statItem(String(localized: "daily_average"),
                                 value: String(format: "%.1fL", analytics.averageIntake))
```

- [ ] **Step 11: Fix `AnalyticsView.swift:158`**

Replace:
```swift
                        statItem(String(localized: "consistency"), value: String(format: "%.0f", analytics.consistencyScore))
```
With:
```swift
                        statItem(String(localized: "consistency"),
                                 value: String(format: "%.0f", analytics.consistencyScore))
```

- [ ] **Step 12: Fix `AnalyticsView.swift:215`**

Replace:
```swift
                        statItem(String(localized: "good_days"), value: String(format: "%.0f%%", analytics.goodDaysPercentage))
```
With:
```swift
                        statItem(String(localized: "good_days"),
                                 value: String(format: "%.0f%%", analytics.goodDaysPercentage))
```

- [ ] **Step 13: Build — confirm zero errors**

Cmd+B. Expected: Build Succeeded.

---

## Task 2: Fix long lines in test files + rename type

**Files:**
- Modify: `HealthTrackerTests/Domain/UseCases/ScheduleNotificationsUseCaseTests.swift:109`
- Modify: `HealthTrackerTests/Domain/Entities/DayDataTests.swift:273`
- Modify: `HealthTrackerTests/Presentation/ViewModels/MainViewModelTests.swift:25`
- Rename+Modify: `HealthTrackerTests/Domain/UseCases/RequestNotificationPermissionUseCaseTests.swift`

- [ ] **Step 1: Fix `ScheduleNotificationsUseCaseTests.swift:109`**

Replace:
```swift
        let expectedTitle = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "HealthTracker"
```
With:
```swift
        let expectedTitle = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")
            as? String ?? "HealthTracker"
```

- [ ] **Step 2: Fix `DayDataTests.swift:273`**

Replace:
```swift
        dayData.addWorkout(Workout(description: "Long run", duration: Workout.Duration(minutes: 120))) // Even with long workout
```
With:
```swift
        // Even with long workout
        dayData.addWorkout(Workout(description: "Long run", duration: Workout.Duration(minutes: 120)))
```

- [ ] **Step 3: Fix `MainViewModelTests.swift:25`**

Replace:
```swift
    private func createViewModel() -> (
        viewModel: MainViewModel,
        mockRepository: MockHealthDataRepository
    ) {
```
With:
```swift
    private func createViewModel() -> (viewModel: MainViewModel,
                                       mockRepository: MockHealthDataRepository) {
```

- [ ] **Step 4: Rename type in `RequestNotificationPermissionUseCaseTests.swift`**

Replace:
```swift
struct RequestNotificationPermissionUseCaseTests {
```
With:
```swift
struct RequestNotifPermissionUseCaseTests {
```

Then in Xcode's Project Navigator, rename the file from `RequestNotificationPermissionUseCaseTests.swift` to `RequestNotifPermissionUseCaseTests.swift`.

- [ ] **Step 5: Build and run all tests**

Cmd+B then Cmd+U. Expected: Build Succeeded, all tests pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "fix: resolve batch 1 SwiftLint warnings (line_length, for_where, type_name)"
```
