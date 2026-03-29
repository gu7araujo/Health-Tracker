# SwiftLint Warnings Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate all 22 SwiftLint warnings across 10 source files with no logic changes, proper struct extractions, and meaningful refactors.

**Architecture:** Three ordered batches — mechanical line-wrapping first, struct extractions second, structural refactors last. Each batch ends with a build + test verification and a commit.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing (`#expect`/`#require`), SwiftLint

---

## File Structure

### Batch 1 — Modified only
- `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift` — wrap line 38
- `HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift` — wrap line 119
- `HealthTracker/Data/Migration/DataMigration.swift` — for_where on lines 75–81
- `HealthTracker/Presentation/Views/AddEditModal.swift` — wrap line 81
- `HealthTracker/Presentation/Views/MainView.swift` — wrap lines 163, 288
- `HealthTracker/Presentation/Views/AnalyticsView.swift` — wrap lines 94, 124, 126, 155, 158, 215
- `HealthTrackerTests/Domain/UseCases/ScheduleNotificationsUseCaseTests.swift` — wrap line 109
- `HealthTrackerTests/Domain/Entities/DayDataTests.swift` — wrap line 273
- `HealthTrackerTests/Presentation/ViewModels/MainViewModelTests.swift` — wrap line 25
- `HealthTrackerTests/Domain/UseCases/RequestNotificationPermissionUseCaseTests.swift` — rename type + file

### Batch 2 — Modified
- `HealthTracker/Presentation/Views/Components/Charts/MoodBarChart.swift` — add `MoodChartItem` struct, replace tuple
- `HealthTracker/Presentation/Views/Components/Charts/OverallHealthRingChart.swift` — add `StatusChartItem` struct, replace tuple
- `HealthTracker/Presentation/Views/MainView.swift` — remove extracted types, keep only `MainView`

### Batch 2 — Created
- `HealthTracker/Presentation/Views/MealsSectionView.swift`
- `HealthTracker/Presentation/Views/WaterSectionView.swift`
- `HealthTracker/Presentation/Views/WorkoutsSectionView.swift`
- `HealthTracker/Presentation/Views/MoodSectionView.swift`
- `HealthTracker/Presentation/Views/Components/EmptyListRow.swift`
- `HealthTracker/Extensions/UUID+Identifiable.swift`

### Batch 3 — Modified
- `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift` — strip to init + execute only
- `HealthTrackerTests/Presentation/ViewModels/MainViewModelTests.swift` — deleted (replaced by 4 files)

### Batch 3 — Created
- `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Meals.swift`
- `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Water.swift`
- `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Workout.swift`
- `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Mood.swift`
- `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Overall.swift`
- `HealthTrackerTests/Presentation/ViewModels/MainViewModelLoadTests.swift`
- `HealthTrackerTests/Presentation/ViewModels/MainViewModelDateTests.swift`
- `HealthTrackerTests/Presentation/ViewModels/MainViewModelWaterMoodTests.swift`
- `HealthTrackerTests/Presentation/ViewModels/MainViewModelMealWorkoutTests.swift`

---

## Task 1: Batch 1 — Wrap long lines in production code

**Files:**
- Modify: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift:38`
- Modify: `HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift:119`
- Modify: `HealthTracker/Data/Migration/DataMigration.swift:77`
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

- [ ] **Step 3: Fix `DataMigration.swift:75–81` (for_where)**

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

- [ ] **Step 13: Build and confirm zero errors**

Build the project in Xcode (Cmd+B). Expected: Build Succeeded with no errors.

---

## Task 2: Batch 1 — Wrap long lines in test files + rename type

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

Then rename the file itself in Xcode's Project Navigator from `RequestNotificationPermissionUseCaseTests.swift` to `RequestNotifPermissionUseCaseTests.swift`.

- [ ] **Step 5: Build and run all tests**

Build (Cmd+B), then run all tests (Cmd+U). Expected: Build Succeeded, all tests pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "fix: resolve batch 1 SwiftLint warnings (line_length, for_where, type_name)"
```

---

## Task 3: Batch 2 — Replace large tuples with named structs

**Files:**
- Modify: `HealthTracker/Presentation/Views/Components/Charts/MoodBarChart.swift`
- Modify: `HealthTracker/Presentation/Views/Components/Charts/OverallHealthRingChart.swift`

- [ ] **Step 1: Add `MoodChartItem` to `MoodBarChart.swift`**

At the bottom of the file, before the `#Preview`, add:
```swift
private struct MoodChartItem {
    let mood: Mood
    let count: Int
    let color: Color
}
```

Then update `chartData` from:
```swift
    private var chartData: [(mood: Mood, count: Int, color: Color)] {
        distribution
            .filter { $0.value > 0 }
            .map { mood, count in
                let color: Color = switch mood {
                case .good: .green
                case .neutral: .orange
                case .sad: .red
                }
                return (mood: mood, count: count, color: color)
            }
            .sorted { $0.mood.rawValue < $1.mood.rawValue }
    }
```
To:
```swift
    private var chartData: [MoodChartItem] {
        distribution
            .filter { $0.value > 0 }
            .map { mood, count in
                let color: Color = switch mood {
                case .good: .green
                case .neutral: .orange
                case .sad: .red
                }
                return MoodChartItem(mood: mood, count: count, color: color)
            }
            .sorted { $0.mood.rawValue < $1.mood.rawValue }
    }
```

- [ ] **Step 2: Add `StatusChartItem` to `OverallHealthRingChart.swift`**

At the bottom of the file, before `#Preview`, add:
```swift
private struct StatusChartItem {
    let status: DayStatus
    let count: Int
    let color: Color
}
```

Then update `chartData` from:
```swift
    private var chartData: [(status: DayStatus, count: Int, color: Color)] {
        statusDistribution
            .filter { $0.value > 0 }
            .map { status, count in
                let color: Color = status.color ?? .clear
                return (status: status, count: count, color: color)
            }
            .sorted { $0.count > $1.count }
    }
```
To:
```swift
    private var chartData: [StatusChartItem] {
        statusDistribution
            .filter { $0.value > 0 }
            .map { status, count in
                let color: Color = status.color ?? .clear
                return StatusChartItem(status: status, count: count, color: color)
            }
            .sorted { $0.count > $1.count }
    }
```

Also update `totalDays`:
```swift
    private var totalDays: Int {
        chartData.reduce(0) { $0 + $1.count }
    }
```
(No change needed — `.count` still works on `StatusChartItem`.)

- [ ] **Step 3: Build and confirm zero errors**

Build (Cmd+B). Expected: Build Succeeded.

---

## Task 4: Batch 2 — Extract `MainView.swift` section views into separate files

**Files:**
- Modify: `HealthTracker/Presentation/Views/MainView.swift`
- Create: `HealthTracker/Presentation/Views/MealsSectionView.swift`
- Create: `HealthTracker/Presentation/Views/WaterSectionView.swift`
- Create: `HealthTracker/Presentation/Views/WorkoutsSectionView.swift`
- Create: `HealthTracker/Presentation/Views/MoodSectionView.swift`
- Create: `HealthTracker/Presentation/Views/Components/EmptyListRow.swift`
- Create: `HealthTracker/Extensions/UUID+Identifiable.swift`

- [ ] **Step 1: Create `MealsSectionView.swift`**

In Xcode, create a new Swift file at `HealthTracker/Presentation/Views/MealsSectionView.swift` with this content (note: `private struct` → `struct`):

```swift
//
//  MealsSectionView.swift
//  HealthTracker
//

import SwiftUI

struct MealsSectionView: View {
    let meals: [Meal]
    @Binding var editingMealId: UUID?
    let onDelete: (UUID) -> Void

    var body: some View {
        Group {
            Text(String(localized: "meals_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            if !meals.isEmpty {
                ForEach(meals) { meal in
                    CardView(
                        internalPadding: .init(
                            top: 15,
                            leading: 15,
                            bottom: 15,
                            trailing: 15
                        ),
                        applyGlassEffect: false,
                        backgroundColor: .constant(
                            Color(
                                .secondarySystemBackground
                            )
                        )
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(meal.description)
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                Text(String(
                                    format: String(localized: "quantity_label"),
                                    meal.quantity.localizedName))
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text(String(format: String(localized: "satisfaction_label"), meal.satisfaction.localizedName))
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(meal.id)
                        } label: {
                            Label(String(localized: "delete_action"), systemImage: "trash")
                        }
                        Button {
                            editingMealId = meal.id
                        } label: {
                            Label(String(localized: "edit_action"), systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20))
                }
            } else {
                EmptyListRow()
            }
        }
    }
}
```

- [ ] **Step 2: Create `WaterSectionView.swift`**

Create `HealthTracker/Presentation/Views/WaterSectionView.swift`:

```swift
//
//  WaterSectionView.swift
//  HealthTracker
//

import SwiftUI

struct WaterSectionView: View {
    let water: Double
    let waterIntake: Double
    let onUpdateWater: (Double) -> Void

    var body: some View {
        Group {
            Text(String(localized: "water_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            CardView(
                internalPadding: .init(
                    top: 15,
                    leading: 15,
                    bottom: 15,
                    trailing: 15
                ),
                applyGlassEffect: false,
                backgroundColor: .constant(
                    Color(
                        .secondarySystemBackground
                    )
                )
            ) {
                VStack {
                    (Text(water, format: .number.precision(.fractionLength(1)))
                        + Text(String(localized: "water_unit")))
                        .font(.title)
                        .bold()
                    Slider(
                        value: Binding(
                            get: { waterIntake },
                            set: { onUpdateWater($0) }
                        ),
                        in: 0 ... 5,
                        step: 0.1
                    ) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text(String(localized: "water_min_label"))
                            .font(.caption)
                    } maximumValueLabel: {
                        Text(String(localized: "water_max_label"))
                            .font(.caption)
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 15, trailing: 20))
        }
    }
}
```

- [ ] **Step 3: Create `WorkoutsSectionView.swift`**

Create `HealthTracker/Presentation/Views/WorkoutsSectionView.swift`:

```swift
//
//  WorkoutsSectionView.swift
//  HealthTracker
//

import SwiftUI

struct WorkoutsSectionView: View {
    let workouts: [Workout]
    @Binding var editingWorkoutId: UUID?
    let onDelete: (UUID) -> Void

    var body: some View {
        Group {
            Text(String(localized: "workouts_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            if !workouts.isEmpty {
                ForEach(workouts) { workout in
                    CardView(
                        internalPadding: .init(
                            top: 15,
                            leading: 15,
                            bottom: 15,
                            trailing: 15
                        ),
                        applyGlassEffect: false,
                        backgroundColor: .constant(
                            Color(
                                .secondarySystemBackground
                            )
                        )
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(workout.description)
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                Text(String(
                                    format: String(localized: "workout_time_label"),
                                    workout.duration.localizedName))
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(workout.id)
                        } label: {
                            Label(String(localized: "delete_action"), systemImage: "trash")
                        }
                        Button {
                            editingWorkoutId = workout.id
                        } label: {
                            Label(String(localized: "edit_action"), systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20))
                }
            } else {
                EmptyListRow()
            }
        }
    }
}
```

- [ ] **Step 4: Create `MoodSectionView.swift`**

Create `HealthTracker/Presentation/Views/MoodSectionView.swift`:

```swift
//
//  MoodSectionView.swift
//  HealthTracker
//

import SwiftUI

struct MoodSectionView: View {
    let currentMood: Mood?
    let onUpdateMood: (Mood) -> Void

    var body: some View {
        Group {
            Text(String(localized: "mood_section"))
                .font(.title2)
                .bold()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            CardView(
                internalPadding: .init(
                    top: 15,
                    leading: 15,
                    bottom: 15,
                    trailing: 15
                ),
                applyGlassEffect: false,
                backgroundColor: .constant(
                    Color(
                        .secondarySystemBackground
                    )
                )
            ) {
                VStack(alignment: .leading) {
                    Text(String(localized: "mood_prompt"))
                        .font(.headline)
                        .padding(.bottom, 15)

                    HStack {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            moodButton(for: mood)
                        }
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        }
    }

    private func moodButton(for mood: Mood) -> some View {
        let isSelected = currentMood == mood

        return CardView(
            applyGlassEffect: true,
            glassTint: isSelected ? mood.color : nil
        ) {
            onUpdateMood(mood)
        } content: {
            HStack {
                Spacer()
                VStack {
                    Text(mood.emoji)
                        .font(.title)
                    Text(mood.localizedName)
                        .font(.caption)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 5: Create `EmptyListRow.swift`**

Create `HealthTracker/Presentation/Views/Components/EmptyListRow.swift`:

```swift
//
//  EmptyListRow.swift
//  HealthTracker
//

import SwiftUI

struct EmptyListRow: View {
    var body: some View {
        HStack {
            Spacer()
            Text(String(localized: "empty_list"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
    }
}
```

- [ ] **Step 6: Create `UUID+Identifiable.swift`**

Create `HealthTracker/Extensions/UUID+Identifiable.swift`:

```swift
//
//  UUID+Identifiable.swift
//  HealthTracker
//

import Foundation

extension UUID: @retroactive Identifiable {
    public var id: UUID {
        self
    }
}
```

- [ ] **Step 7: Strip `MainView.swift` down to just `MainView`**

Replace the entire content of `MainView.swift` with:

```swift
//
//  MainView.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import SwiftUI

struct MainView: View {
    @State private var viewModel = MainViewModel()
    @State private var addingSection: HealthSection?
    @State private var editingMealId: UUID?
    @State private var editingWorkoutId: UUID?
    @State private var showAddSelectionAlert = false

    var body: some View {
        NavigationStack {
            List {
                datePickerSection
                MealsSectionView(
                    meals: viewModel.currentDayData?.meals ?? [],
                    editingMealId: $editingMealId,
                    onDelete: { viewModel.deleteMeal(withId: $0) }
                )
                WaterSectionView(
                    water: viewModel.currentDayData?.water ?? 0,
                    waterIntake: viewModel.waterIntake,
                    onUpdateWater: { viewModel.updateWater($0) }
                )
                WorkoutsSectionView(
                    workouts: viewModel.currentDayData?.workouts ?? [],
                    editingWorkoutId: $editingWorkoutId,
                    onDelete: { viewModel.deleteWorkout(withId: $0) }
                )
                MoodSectionView(
                    currentMood: viewModel.currentDayData?.mood,
                    onUpdateMood: { viewModel.updateMood($0) }
                )
                .padding(.bottom, 8)
            }
            .navigationTitle(String(localized: "app_title"))
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "add_button"), systemImage: "plus") {
                        showAddSelectionAlert = true
                    }
                }
            }
            .alert(String(localized: "add_record_title"), isPresented: $showAddSelectionAlert) {
                Button(String(localized: "meal_option")) {
                    addingSection = .meal
                }
                Button(String(localized: "workout_option")) {
                    addingSection = .workout
                }
                Button(String(localized: "cancel_button"), role: .cancel) {}
            } message: {
                Text(String(localized: "add_record_message"))
            }
        }
        .onFirstAppear {
            viewModel.loadData()
        }
        .sheet(item: $addingSection) { section in
            AddEditModal(
                viewModel: viewModel,
                section: section,
                mealId: nil,
                workoutId: nil
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingMealId) { mealId in
            AddEditModal(
                viewModel: viewModel,
                section: .meal,
                mealId: mealId,
                workoutId: nil
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingWorkoutId) { workoutId in
            AddEditModal(
                viewModel: viewModel,
                section: .workout,
                mealId: nil,
                workoutId: workoutId
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        VStack {
            CalendarStrip(selectedDate: $viewModel.selectedDate, days: viewModel.days)
            if let explanation = viewModel.currentDayExplanation,
               viewModel.currentDayStatus != .noData,
               viewModel.currentDayStatus != .incomplete,
               viewModel.currentDayStatus != .optimal
            {
                Text(explanation)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 28)
                    .transition(.opacity)
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 15, leading: 0, bottom: 23, trailing: 0))
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentDayStatus)
    }
}
```

- [ ] **Step 8: Build and run all tests**

Build (Cmd+B), then run all tests (Cmd+U). Expected: Build Succeeded, all tests pass.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "fix: resolve batch 2 SwiftLint warnings (large_tuple, file_length)"
```

---

## Task 5: Batch 3 — Split `CalculateAnalyticsUseCase` into extension files

**Files:**
- Modify: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Meals.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Water.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Workout.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Mood.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Overall.swift`

- [ ] **Step 1: Slim down `CalculateAnalyticsUseCase.swift`**

Replace the entire file content with:

```swift
//
//  CalculateAnalyticsUseCase.swift
//  HealthTracker
//
//  Created by Claude on 02/23/26.
//

import Foundation

/// Use case for calculating comprehensive analytics across all health metrics
final class CalculateAnalyticsUseCase {
    private let repository: HealthDataRepositoryProtocol
    private let logger: LoggerProtocol

    init(repository: HealthDataRepositoryProtocol, logger: LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }

    /// Calculates analytics for the specified period
    /// - Parameter period: The time period to analyze
    /// - Returns: Complete analytics data for all health metrics
    func execute(for period: AnalyticsPeriod) -> AnalyticsData {
        let days = repository.loadDaysInRange(period.dateRange)
        logger.debug("Calculating analytics for \(days.count) days")

        let dayDataArray = days.map(\.dayData)

        let analytics = AnalyticsData(
            mealAnalytics: calculateMealAnalytics(from: dayDataArray, period: period),
            waterAnalytics: calculateWaterAnalytics(from: dayDataArray),
            workoutAnalytics: calculateWorkoutAnalytics(from: dayDataArray),
            moodAnalytics: calculateMoodAnalytics(from: dayDataArray, period: period),
            overallAnalytics: calculateOverallAnalytics(from: dayDataArray),
            period: period
        )

        let meals = analytics.mealAnalytics.totalMeals
        let workouts = analytics.workoutAnalytics.totalWorkouts
        logger.info("Analytics calculated: \(meals) meals, \(workouts) workouts")

        return analytics
    }
}
```

- [ ] **Step 2: Create `CalculateAnalyticsUseCase+Meals.swift`**

```swift
//
//  CalculateAnalyticsUseCase+Meals.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateMealAnalytics(from days: [DayData], period _: AnalyticsPeriod) -> MealAnalytics {
        let allMeals = days.flatMap(\.meals)

        let totalMeals = allMeals.count

        let averageSatisfaction: Double
        if !allMeals.isEmpty {
            let totalSatisfaction = allMeals.reduce(0.0) { sum, meal in
                let percentage = switch meal.satisfaction {
                case .thirty: 30.0
                case .fifty: 50.0
                case .eighty: 80.0
                case .hundred: 100.0
                }
                return sum + percentage
            }
            averageSatisfaction = totalSatisfaction / Double(allMeals.count)
        } else {
            averageSatisfaction = 0.0
        }

        let optimalDaysCount = days.filter { day in
            !day.meals.isEmpty && day.meals.allSatisfy { meal in
                (meal.quantity == .small || meal.quantity == .verySmall) && meal.satisfaction == .fifty
            }
        }.count

        return MealAnalytics(
            totalMeals: totalMeals,
            averageSatisfaction: averageSatisfaction,
            quantityDistribution: buildQuantityDistribution(from: allMeals),
            satisfactionDistribution: buildSatisfactionDistribution(from: allMeals),
            optimalDaysCount: optimalDaysCount,
            dailyCounts: buildDailyCounts(from: days),
            satisfactionTrend: buildSatisfactionTrend(from: days)
        )
    }

    private func buildQuantityDistribution(from meals: [Meal]) -> [Meal.Quantity: Int] {
        var dist: [Meal.Quantity: Int] = [:]
        for quantity in Meal.Quantity.allCases {
            dist[quantity] = meals.filter { $0.quantity == quantity }.count
        }
        return dist
    }

    private func buildSatisfactionDistribution(from meals: [Meal]) -> [Meal.Satisfaction: Int] {
        var dist: [Meal.Satisfaction: Int] = [:]
        for satisfaction in Meal.Satisfaction.allCases {
            dist[satisfaction] = meals.filter { $0.satisfaction == satisfaction }.count
        }
        return dist
    }

    private func buildDailyCounts(from days: [DayData]) -> [Date: Int] {
        var counts: [Date: Int] = [:]
        for day in days {
            let normalizedDate = Calendar.current.startOfDay(for: day.date)
            counts[normalizedDate] = day.meals.count
        }
        return counts
    }

    private func buildSatisfactionTrend(from days: [DayData]) -> [Date: [Meal.Satisfaction: Int]] {
        var trend: [Date: [Meal.Satisfaction: Int]] = [:]
        for day in days where !day.meals.isEmpty {
            let normalizedDate = Calendar.current.startOfDay(for: day.date)
            var dist: [Meal.Satisfaction: Int] = [:]
            for satisfaction in Meal.Satisfaction.allCases {
                dist[satisfaction] = day.meals.filter { $0.satisfaction == satisfaction }.count
            }
            trend[normalizedDate] = dist
        }
        return trend
    }
}
```

- [ ] **Step 3: Create `CalculateAnalyticsUseCase+Water.swift`**

```swift
//
//  CalculateAnalyticsUseCase+Water.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateWaterAnalytics(from days: [DayData]) -> WaterAnalytics {
        let waterDays = days.compactMap { day -> (Date, Double)? in
            guard let water = day.water, water > 0 else { return nil }
            return (Calendar.current.startOfDay(for: day.date), water)
        }

        let waterIntakes = waterDays.map(\.1)

        let averageIntake = waterIntakes.isEmpty ? 0.0 : waterIntakes.reduce(0.0, +) / Double(waterIntakes.count)
        let maxIntake = waterIntakes.max() ?? 0.0
        let minIntake = waterIntakes.min() ?? 0.0

        let daysAboveOptimal = waterIntakes.filter { $0 >= 1.8 }.count
        let daysAboveModerate = waterIntakes.filter { $0 >= 1.0 }.count

        let consistencyScore: Double
        if waterIntakes.count > 1 {
            let variance = waterIntakes.reduce(0.0) { $0 + pow($1 - averageIntake, 2) } / Double(waterIntakes.count)
            let standardDeviation = sqrt(variance)
            consistencyScore = max(0, 100 - (standardDeviation * 50))
        } else {
            consistencyScore = 100.0
        }

        var dailyIntake: [Date: Double] = [:]
        for (date, intake) in waterDays {
            dailyIntake[date] = intake
        }

        return WaterAnalytics(
            averageIntake: averageIntake,
            maxIntake: maxIntake,
            minIntake: minIntake,
            daysAboveOptimal: daysAboveOptimal,
            daysAboveModerate: daysAboveModerate,
            consistencyScore: consistencyScore,
            dailyIntake: dailyIntake
        )
    }
}
```

- [ ] **Step 4: Create `CalculateAnalyticsUseCase+Workout.swift`**

```swift
//
//  CalculateAnalyticsUseCase+Workout.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateWorkoutAnalytics(from days: [DayData]) -> WorkoutAnalytics {
        let allWorkouts = days.flatMap(\.workouts)

        let totalWorkouts = allWorkouts.count
        let totalMinutes = allWorkouts.reduce(0) { $0 + $1.duration.minutes }
        let averageDuration = allWorkouts.isEmpty ? 0 : totalMinutes / totalWorkouts

        let (currentStreak, longestStreak) = calculateStreaks(
            in: days,
            condition: { !$0.workouts.isEmpty }
        )

        var weekdayDist: [Int: (count: Int, avgDuration: Int)] = [:]
        let calendar = Calendar.current
        for day in days where !day.workouts.isEmpty {
            let weekday = calendar.component(.weekday, from: day.date)
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
            let dayMinutes = day.workouts.reduce(0) { $0 + $1.duration.minutes }
            let existing = weekdayDist[adjustedWeekday] ?? (count: 0, avgDuration: 0)
            let newCount = existing.count + 1
            let newAvg = (existing.avgDuration * existing.count + dayMinutes) / newCount
            weekdayDist[adjustedWeekday] = (count: newCount, avgDuration: newAvg)
        }

        var weeklyVolume: [Date: Int] = [:]
        for day in days where !day.workouts.isEmpty {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: day.date)?.start {
                let normalizedWeekStart = calendar.startOfDay(for: weekStart)
                let dayMinutes = day.workouts.reduce(0) { $0 + $1.duration.minutes }
                weeklyVolume[normalizedWeekStart, default: 0] += dayMinutes
            }
        }

        var durationDist: [DurationRange: Int] = [:]
        for workout in allWorkouts {
            let range = DurationRange(minutes: workout.duration.minutes)
            durationDist[range, default: 0] += 1
        }

        return WorkoutAnalytics(
            totalWorkouts: totalWorkouts,
            totalMinutes: totalMinutes,
            averageDuration: averageDuration,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weekdayDistribution: weekdayDist,
            weeklyVolume: weeklyVolume,
            durationDistribution: durationDist
        )
    }

    func calculateStreaks(
        in days: [DayData],
        condition: (DayData) -> Bool
    ) -> (current: Int, longest: Int) {
        guard !days.isEmpty else { return (0, 0) }

        let sorted = days.sorted { $0.date > $1.date }
        let calendar = Calendar.current

        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var previousDate: Date?

        for day in sorted {
            let meetsCondition = condition(day)

            if meetsCondition {
                if let prev = previousDate {
                    let daysBetween = calendar.dateComponents([.day], from: day.date, to: prev).day ?? 0
                    if daysBetween == 1 {
                        tempStreak += 1
                    } else {
                        longestStreak = max(longestStreak, tempStreak)
                        tempStreak = 1
                    }
                } else {
                    tempStreak = 1
                }

                if previousDate == nil || calendar.isDateInToday(day.date) {
                    currentStreak = tempStreak
                }

                previousDate = day.date
            } else {
                longestStreak = max(longestStreak, tempStreak)
                if previousDate == nil {
                    currentStreak = 0
                }
                tempStreak = 0
                previousDate = day.date
            }
        }

        longestStreak = max(longestStreak, tempStreak)

        return (currentStreak, longestStreak)
    }
}
```

- [ ] **Step 5: Create `CalculateAnalyticsUseCase+Mood.swift`**

```swift
//
//  CalculateAnalyticsUseCase+Mood.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateMoodAnalytics(from days: [DayData], period _: AnalyticsPeriod) -> MoodAnalytics {
        let moodDays = days.compactMap { day -> (Date, Mood)? in
            guard let mood = day.mood else { return nil }
            return (Calendar.current.startOfDay(for: day.date), mood)
        }

        var distribution: [Mood: Int] = [:]
        for mood in Mood.allCases {
            distribution[mood] = moodDays.filter { $0.1 == mood }.count
        }

        let goodDaysCount = distribution[.good] ?? 0
        let goodDaysPercentage = moodDays.isEmpty ? 0.0 : (Double(goodDaysCount) / Double(moodDays.count)) * 100.0

        var dailyMood: [Date: Mood] = [:]
        for (date, mood) in moodDays {
            dailyMood[date] = mood
        }

        let (bestWeek, worstWeek) = calculateBestWorstWeeks(from: days)

        return MoodAnalytics(
            distribution: distribution,
            goodDaysPercentage: goodDaysPercentage,
            dailyMood: dailyMood,
            bestWeek: bestWeek,
            worstWeek: worstWeek
        )
    }

    private func calculateBestWorstWeeks(from days: [DayData]) -> (best: Date?, worst: Date?) {
        let calendar = Calendar.current
        var weeklyMoods: [Date: [Mood]] = [:]

        for day in days {
            guard let mood = day.mood else { continue }
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: day.date)?.start {
                let normalizedWeekStart = calendar.startOfDay(for: weekStart)
                weeklyMoods[normalizedWeekStart, default: []].append(mood)
            }
        }

        guard !weeklyMoods.isEmpty else { return (nil, nil) }

        let weekScores = weeklyMoods.map { week, moods in
            let goodCount = moods.filter { $0 == .good }.count
            let percentage = Double(goodCount) / Double(moods.count)
            return (week: week, score: percentage)
        }

        let bestWeek = weekScores.max(by: { $0.score < $1.score })?.week
        let worstWeek = weekScores.min(by: { $0.score < $1.score })?.week

        return (bestWeek, worstWeek)
    }
}
```

- [ ] **Step 6: Create `CalculateAnalyticsUseCase+Overall.swift`**

```swift
//
//  CalculateAnalyticsUseCase+Overall.swift
//  HealthTracker
//

import Foundation

extension CalculateAnalyticsUseCase {
    func calculateOverallAnalytics(from days: [DayData]) -> OverallAnalytics {
        let recordedDays = days.compactMap(RecordedDayData.init)

        let daysTracked = recordedDays.count

        var statusDist: [DayStatus: Int] = [
            .optimal: 0,
            .moderate: 0,
            .poor: 0,
            .incomplete: 0,
            .noData: 0
        ]

        for day in recordedDays {
            let status = day.dayData.status
            statusDist[status, default: 0] += 1
        }

        let optimalDays = statusDist[.optimal] ?? 0
        let moderateDays = statusDist[.moderate] ?? 0
        let poorDays = statusDist[.poor] ?? 0
        let incompleteDays = statusDist[.incomplete] ?? 0

        let (currentOptimalStreak, longestOptimalStreak) = calculateStreaks(
            in: days,
            condition: { $0.status == .optimal }
        )

        let healthScore: Double = if daysTracked > 0 {
            (Double(optimalDays) * 100.0 +
                Double(moderateDays) * 60.0 +
                Double(poorDays) * 30.0 +
                Double(incompleteDays) * 10.0) / Double(daysTracked)
        } else {
            0.0
        }

        return OverallAnalytics(
            daysTracked: daysTracked,
            optimalDays: optimalDays,
            moderateDays: moderateDays,
            poorDays: poorDays,
            incompleteDays: incompleteDays,
            currentOptimalStreak: currentOptimalStreak,
            longestOptimalStreak: longestOptimalStreak,
            healthScore: healthScore,
            statusDistribution: statusDist
        )
    }
}
```

- [ ] **Step 7: Build and run all tests**

Build (Cmd+B), then run all tests (Cmd+U). Expected: Build Succeeded, all tests pass.

---

## Task 6: Batch 3 — Split `MainViewModelTests` into domain-focused files

**Files:**
- Create: `HealthTrackerTests/Presentation/ViewModels/MainViewModelLoadTests.swift`
- Create: `HealthTrackerTests/Presentation/ViewModels/MainViewModelDateTests.swift`
- Create: `HealthTrackerTests/Presentation/ViewModels/MainViewModelWaterMoodTests.swift`
- Create: `HealthTrackerTests/Presentation/ViewModels/MainViewModelMealWorkoutTests.swift`
- Delete: `HealthTrackerTests/Presentation/ViewModels/MainViewModelTests.swift`

- [ ] **Step 1: Create `MainViewModelLoadTests.swift`**

```swift
//
//  MainViewModelLoadTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MainViewModelLoadTests {
    private func createViewModel() -> (viewModel: MainViewModel,
                                       mockRepository: MockHealthDataRepository) {
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let loadUseCase = LoadDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let saveUseCase = SaveDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let mockNotificationService = MockNotificationService()
        let cancelNotificationsUseCase = CancelNotificationsUseCase(notificationService: mockNotificationService, logger: mockLogger)
        let viewModel = MainViewModel(
            loadUseCase: loadUseCase,
            saveUseCase: saveUseCase,
            cancelNotificationsUseCase: cancelNotificationsUseCase,
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

    // MARK: - Initialization Tests

    @Test func initialization_setsDefaultState() {
        let (viewModel, _) = createViewModel()

        #expect(viewModel.days.isEmpty)
    }

    // MARK: - Load Data Tests

    @Test func loadData_loadsFromRepository() throws {
        let (viewModel, mockRepository) = createViewModel()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]

        viewModel.selectedDate = day1.dayData.date
        viewModel.loadData()

        #expect(viewModel.days.count == 2)
        #expect(Calendar.current.isDate(viewModel.days[0].date, inSameDayAs: day1.dayData.date))
        #expect(Calendar.current.isDate(viewModel.days[1].date, inSameDayAs: day2.dayData.date))
    }

    @Test func loadData_createsEmptyDayForSelectedDate() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.loadData()

        #expect(viewModel.days.count == 1)
        #expect(viewModel.days[0].meals.isEmpty)
    }
}
```

- [ ] **Step 2: Create `MainViewModelDateTests.swift`**

```swift
//
//  MainViewModelDateTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MainViewModelDateTests {
    private func createViewModel() -> (viewModel: MainViewModel,
                                       mockRepository: MockHealthDataRepository) {
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let loadUseCase = LoadDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let saveUseCase = SaveDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let mockNotificationService = MockNotificationService()
        let cancelNotificationsUseCase = CancelNotificationsUseCase(notificationService: mockNotificationService, logger: mockLogger)
        let viewModel = MainViewModel(
            loadUseCase: loadUseCase,
            saveUseCase: saveUseCase,
            cancelNotificationsUseCase: cancelNotificationsUseCase,
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

    // MARK: - Date Selection Tests

    @Test func selectedDate_change_ensuresDayDataExists() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []

        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.loadData()

        #expect(viewModel.days.count == 1)
        #expect(Calendar.current.isDate(viewModel.days[0].date, inSameDayAs: TestDataBuilder.fixedDate))
    }

    @Test func selectedDate_change_doesNotDuplicateExistingDay() throws {
        let (viewModel, mockRepository) = createViewModel()
        let existingDay = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        mockRepository.loadAllDaysResult = [existingDay]

        viewModel.selectedDate = TestDataBuilder.fixedDate
        viewModel.loadData()

        viewModel.selectedDate = TestDataBuilder.fixedDate

        #expect(viewModel.days.count == 1)
    }

    // MARK: - Current Day Data Tests

    @Test func currentDayData_returnsCorrectDay() throws {
        let (viewModel, mockRepository) = createViewModel()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]
        viewModel.loadData()

        viewModel.selectedDate = TestDataBuilder.fixedDate

        #expect(viewModel.currentDayData?.date == day1.dayData.date)
    }

    @Test func dateSwitch_preservesData() throws {
        let (viewModel, mockRepository) = createViewModel()
        let day1 = try #require(TestDataBuilder.makeRecordedOptimalDay(date: TestDataBuilder.fixedDate))
        let day2 = try #require(TestDataBuilder.makeRecordedModerateDay(date: TestDataBuilder.fixedDatePlusOne))
        mockRepository.loadAllDaysResult = [day1, day2]
        viewModel.loadData()

        viewModel.selectedDate = TestDataBuilder.fixedDate
        let firstDate = viewModel.currentDayData?.date

        viewModel.selectedDate = TestDataBuilder.fixedDatePlusOne
        let secondDate = viewModel.currentDayData?.date

        viewModel.selectedDate = TestDataBuilder.fixedDate
        let backToFirst = viewModel.currentDayData?.date

        #expect(firstDate == day1.dayData.date)
        #expect(secondDate == day2.dayData.date)
        #expect(backToFirst == day1.dayData.date)
    }
}
```

- [ ] **Step 3: Create `MainViewModelWaterMoodTests.swift`**

```swift
//
//  MainViewModelWaterMoodTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MainViewModelWaterMoodTests {
    private func createViewModel() -> (viewModel: MainViewModel,
                                       mockRepository: MockHealthDataRepository) {
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let loadUseCase = LoadDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let saveUseCase = SaveDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let mockNotificationService = MockNotificationService()
        let cancelNotificationsUseCase = CancelNotificationsUseCase(notificationService: mockNotificationService, logger: mockLogger)
        let viewModel = MainViewModel(
            loadUseCase: loadUseCase,
            saveUseCase: saveUseCase,
            cancelNotificationsUseCase: cancelNotificationsUseCase,
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

    // MARK: - Water Management Tests

    @Test func updateWater_updatesCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateWater(1.5)

        #expect(viewModel.currentDayData?.water == 1.5)
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func updateWater_zeroRemovesWater() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateWater(2.0)
        viewModel.updateWater(0)

        #expect(viewModel.currentDayData?.water == nil)
    }

    @Test func waterIntake_getter_returnsCurrentWater() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateWater(2.5)

        #expect(viewModel.waterIntake == 2.5)
    }

    @Test func waterIntake_getter_returnsZero_whenNil() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        #expect(viewModel.waterIntake == 0)
    }

    // MARK: - Mood Management Tests

    @Test func updateMood_updatesCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateMood(.good)

        #expect(viewModel.currentDayData?.mood == .good)
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func updateMood_changesMood() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateMood(.good)
        viewModel.updateMood(.sad)

        #expect(viewModel.currentDayData?.mood == .sad)
    }
}
```

- [ ] **Step 4: Create `MainViewModelMealWorkoutTests.swift`**

```swift
//
//  MainViewModelMealWorkoutTests.swift
//  HealthTrackerTests
//

import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct MainViewModelMealWorkoutTests {
    private func createViewModel() -> (viewModel: MainViewModel,
                                       mockRepository: MockHealthDataRepository) {
        let mockRepository = MockHealthDataRepository()
        let mockLogger = MockLogger()
        let loadUseCase = LoadDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let saveUseCase = SaveDayDataUseCase(repository: mockRepository, logger: mockLogger)
        let mockNotificationService = MockNotificationService()
        let cancelNotificationsUseCase = CancelNotificationsUseCase(notificationService: mockNotificationService, logger: mockLogger)
        let viewModel = MainViewModel(
            loadUseCase: loadUseCase,
            saveUseCase: saveUseCase,
            cancelNotificationsUseCase: cancelNotificationsUseCase,
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

    // MARK: - Meal Management Tests

    @Test func addMeal_addsToCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        viewModel.addMeal(meal)

        #expect(viewModel.currentDayData?.meals.count == 1)
        #expect(viewModel.currentDayData?.meals.first?.description == "Breakfast")
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func updateMeal_modifiesExistingMeal() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let originalMeal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        viewModel.addMeal(originalMeal)

        var updatedMeal = originalMeal
        updatedMeal.quantity = .large
        viewModel.updateMeal(updatedMeal)

        #expect(viewModel.currentDayData?.meals.count == 1)
        #expect(viewModel.currentDayData?.meals.first?.quantity == .large)
    }

    @Test func meal_withId_returnsCorrectMeal() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        viewModel.addMeal(meal)

        let result = viewModel.meal(withId: meal.id)

        #expect(result?.id == meal.id)
        #expect(result?.description == "Breakfast")
    }

    @Test func meal_withId_returnsNil_whenNotFound() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let result = viewModel.meal(withId: UUID())

        #expect(result == nil)
    }

    @Test func deleteMeal_withId_removesMeal() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let meal = Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty)
        viewModel.addMeal(meal)
        viewModel.deleteMeal(withId: meal.id)

        #expect(viewModel.currentDayData?.meals.isEmpty == true)
    }

    // MARK: - Workout Management Tests

    @Test func addWorkout_addsToCurrentDay() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let workout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(workout)

        #expect(viewModel.currentDayData?.workouts.count == 1)
        #expect(viewModel.currentDayData?.workouts.first?.description == "Run")
        #expect(mockRepository.saveCalledWithDays != nil)
    }

    @Test func updateWorkout_modifiesExistingWorkout() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let originalWorkout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(originalWorkout)

        var updatedWorkout = originalWorkout
        updatedWorkout.duration = Workout.Duration(minutes: 60)
        viewModel.updateWorkout(updatedWorkout)

        #expect(viewModel.currentDayData?.workouts.count == 1)
        #expect(viewModel.currentDayData?.workouts.first?.duration == Workout.Duration(minutes: 60))
    }

    @Test func workout_withId_returnsCorrectWorkout() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let workout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(workout)

        let result = viewModel.workout(withId: workout.id)

        #expect(result?.id == workout.id)
        #expect(result?.description == "Run")
    }

    @Test func workout_withId_returnsNil_whenNotFound() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let result = viewModel.workout(withId: UUID())

        #expect(result == nil)
    }

    @Test func deleteWorkout_withId_removesWorkout() {
        let (viewModel, mockRepository) = createViewModel()
        mockRepository.loadAllDaysResult = []
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        let workout = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(workout)
        viewModel.deleteWorkout(withId: workout.id)

        #expect(viewModel.currentDayData?.workouts.isEmpty == true)
    }

    // MARK: - State Consistency Tests

    @Test func multipleOperations_maintainConsistentState() {
        let (viewModel, _) = createViewModel()
        viewModel.loadData()
        viewModel.selectedDate = TestDataBuilder.fixedDate

        viewModel.updateWater(2.0)
        viewModel.updateMood(.good)
        viewModel.addMeal(Meal(description: "Breakfast", quantity: .small, satisfaction: .fifty))
        viewModel.addWorkout(Workout(description: "Run", duration: Workout.Duration(minutes: 30)))

        let current = viewModel.currentDayData
        #expect(current?.water == 2.0)
        #expect(current?.mood == .good)
        #expect(current?.meals.count == 1)
        #expect(current?.workouts.count == 1)
    }
}
```

- [ ] **Step 5: Delete `MainViewModelTests.swift`**

In Xcode's Project Navigator, right-click `MainViewModelTests.swift` → Delete → Move to Trash.

- [ ] **Step 6: Build and run all tests**

Build (Cmd+B), then run all tests (Cmd+U). Expected: Build Succeeded, all tests pass (same count as before the split).

- [ ] **Step 7: Final commit**

```bash
git add -A
git commit -m "fix: resolve batch 3 SwiftLint warnings (type_body_length, function_body_length)"
```

---

## Verification

After all tasks are complete, trigger a fresh SwiftLint run by doing a clean build (Cmd+Shift+K, then Cmd+B). Expected: zero warnings in the Issue Navigator.
