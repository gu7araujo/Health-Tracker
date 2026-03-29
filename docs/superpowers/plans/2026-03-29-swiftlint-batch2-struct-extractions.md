# Batch 2: Struct Extractions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 3 warnings — 2× `large_tuple`, 1× `file_length` — by introducing named structs and splitting `MainView.swift` into focused files.

**Architecture:** Add private named structs to replace anonymous tuples in chart files. Move the 5 private section views and UUID extension from `MainView.swift` into their own files.

**Tech Stack:** Swift 6, SwiftUI

---

## Task 3: Replace large tuples with named structs

**Files:**
- Modify: `HealthTracker/Presentation/Views/Components/Charts/MoodBarChart.swift`
- Modify: `HealthTracker/Presentation/Views/Components/Charts/OverallHealthRingChart.swift`

- [ ] **Step 1: Add `MoodChartItem` and update `chartData` in `MoodBarChart.swift`**

Before the `#Preview` block, add:
```swift
private struct MoodChartItem {
    let mood: Mood
    let count: Int
    let color: Color
}
```

Replace `chartData`:
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
With:
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

- [ ] **Step 2: Add `StatusChartItem` and update `chartData` in `OverallHealthRingChart.swift`**

Before the `#Preview` block, add:
```swift
private struct StatusChartItem {
    let status: DayStatus
    let count: Int
    let color: Color
}
```

Replace `chartData`:
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
With:
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

- [ ] **Step 3: Build — confirm zero errors**

Cmd+B. Expected: Build Succeeded.

---

## Task 4: Extract `MainView.swift` section views into separate files

**Files:**
- Modify: `HealthTracker/Presentation/Views/MainView.swift`
- Create: `HealthTracker/Presentation/Views/MealsSectionView.swift`
- Create: `HealthTracker/Presentation/Views/WaterSectionView.swift`
- Create: `HealthTracker/Presentation/Views/WorkoutsSectionView.swift`
- Create: `HealthTracker/Presentation/Views/MoodSectionView.swift`
- Create: `HealthTracker/Presentation/Views/Components/EmptyListRow.swift`
- Create: `HealthTracker/Extensions/UUID+Identifiable.swift`

- [ ] **Step 1: Create `MealsSectionView.swift`**

Create `HealthTracker/Presentation/Views/MealsSectionView.swift`:

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
                        internalPadding: .init(top: 15, leading: 15, bottom: 15, trailing: 15),
                        applyGlassEffect: false,
                        backgroundColor: .constant(Color(.secondarySystemBackground))
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
                                Text(String(
                                    format: String(localized: "satisfaction_label"),
                                    meal.satisfaction.localizedName))
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
                internalPadding: .init(top: 15, leading: 15, bottom: 15, trailing: 15),
                applyGlassEffect: false,
                backgroundColor: .constant(Color(.secondarySystemBackground))
            ) {
                VStack {
                    (Text(water, format: .number.precision(.fractionLength(1)))
                        + Text(String(localized: "water_unit")))
                        .font(.title)
                        .bold()
                    Slider(
                        value: Binding(get: { waterIntake }, set: { onUpdateWater($0) }),
                        in: 0 ... 5,
                        step: 0.1
                    ) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text(String(localized: "water_min_label")).font(.caption)
                    } maximumValueLabel: {
                        Text(String(localized: "water_max_label")).font(.caption)
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
                        internalPadding: .init(top: 15, leading: 15, bottom: 15, trailing: 15),
                        applyGlassEffect: false,
                        backgroundColor: .constant(Color(.secondarySystemBackground))
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
                internalPadding: .init(top: 15, leading: 15, bottom: 15, trailing: 15),
                applyGlassEffect: false,
                backgroundColor: .constant(Color(.secondarySystemBackground))
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
                    Text(mood.emoji).font(.title)
                    Text(mood.localizedName).font(.caption)
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
    public var id: UUID { self }
}
```

- [ ] **Step 7: Replace `MainView.swift` with slimmed-down version**

Replace entire content of `HealthTracker/Presentation/Views/MainView.swift`:

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
                Button(String(localized: "meal_option")) { addingSection = .meal }
                Button(String(localized: "workout_option")) { addingSection = .workout }
                Button(String(localized: "cancel_button"), role: .cancel) {}
            } message: {
                Text(String(localized: "add_record_message"))
            }
        }
        .onFirstAppear { viewModel.loadData() }
        .sheet(item: $addingSection) { section in
            AddEditModal(viewModel: viewModel, section: section, mealId: nil, workoutId: nil)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingMealId) { mealId in
            AddEditModal(viewModel: viewModel, section: .meal, mealId: mealId, workoutId: nil)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingWorkoutId) { workoutId in
            AddEditModal(viewModel: viewModel, section: .workout, mealId: nil, workoutId: workoutId)
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

Cmd+B then Cmd+U. Expected: Build Succeeded, all tests pass.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "fix: resolve batch 2 SwiftLint warnings (large_tuple, file_length)"
```
