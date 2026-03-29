# Batch 3: Structural Refactors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 3 warnings — `type_body_length` + `function_body_length` in `CalculateAnalyticsUseCase`, `type_body_length` in `MainViewModelTests` — by splitting into focused extension files and test structs.

**Architecture:** Split `CalculateAnalyticsUseCase` into 5 extension files (one per analytics domain). Split `MainViewModelTests` into 4 test structs grouped by feature. No logic changes.

**Tech Stack:** Swift 6, Swift Testing (`@Test`, `#expect`, `#require`)

---

## Task 5: Split `CalculateAnalyticsUseCase` into extension files

**Files:**
- Modify: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Meals.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Water.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Workout.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Mood.swift`
- Create: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase+Overall.swift`

- [ ] **Step 1: Slim down `CalculateAnalyticsUseCase.swift` to init + execute only**

Replace entire file content:

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
            consistencyScore = max(0, 100 - (sqrt(variance) * 50))
        } else {
            consistencyScore = 100.0
        }

        var dailyIntake: [Date: Double] = [:]
        for (date, intake) in waterDays { dailyIntake[date] = intake }

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

        let (currentStreak, longestStreak) = calculateStreaks(in: days) { !$0.workouts.isEmpty }

        var weekdayDist: [Int: (count: Int, avgDuration: Int)] = [:]
        let calendar = Calendar.current
        for day in days where !day.workouts.isEmpty {
            let weekday = calendar.component(.weekday, from: day.date)
            let adjusted = weekday == 1 ? 7 : weekday - 1
            let dayMinutes = day.workouts.reduce(0) { $0 + $1.duration.minutes }
            let existing = weekdayDist[adjusted] ?? (count: 0, avgDuration: 0)
            let newCount = existing.count + 1
            weekdayDist[adjusted] = (count: newCount, avgDuration: (existing.avgDuration * existing.count + dayMinutes) / newCount)
        }

        var weeklyVolume: [Date: Int] = [:]
        for day in days where !day.workouts.isEmpty {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: day.date)?.start {
                let normalizedWeekStart = calendar.startOfDay(for: weekStart)
                weeklyVolume[normalizedWeekStart, default: 0] += day.workouts.reduce(0) { $0 + $1.duration.minutes }
            }
        }

        var durationDist: [DurationRange: Int] = [:]
        for workout in allWorkouts {
            durationDist[DurationRange(minutes: workout.duration.minutes), default: 0] += 1
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

    func calculateStreaks(in days: [DayData], condition: (DayData) -> Bool) -> (current: Int, longest: Int) {
        guard !days.isEmpty else { return (0, 0) }
        let sorted = days.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var currentStreak = 0, longestStreak = 0, tempStreak = 0
        var previousDate: Date?

        for day in sorted {
            if condition(day) {
                if let prev = previousDate,
                   (calendar.dateComponents([.day], from: day.date, to: prev).day ?? 0) == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
                if previousDate == nil || calendar.isDateInToday(day.date) { currentStreak = tempStreak }
                previousDate = day.date
            } else {
                longestStreak = max(longestStreak, tempStreak)
                if previousDate == nil { currentStreak = 0 }
                tempStreak = 0
                previousDate = day.date
            }
        }
        return (currentStreak, max(longestStreak, tempStreak))
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
        for (date, mood) in moodDays { dailyMood[date] = mood }

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
            guard let mood = day.mood,
                  let weekStart = calendar.dateInterval(of: .weekOfYear, for: day.date)?.start else { continue }
            weeklyMoods[calendar.startOfDay(for: weekStart), default: []].append(mood)
        }
        guard !weeklyMoods.isEmpty else { return (nil, nil) }
        let weekScores = weeklyMoods.map { week, moods in
            (week: week, score: Double(moods.filter { $0 == .good }.count) / Double(moods.count))
        }
        return (weekScores.max(by: { $0.score < $1.score })?.week,
                weekScores.min(by: { $0.score < $1.score })?.week)
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

        var statusDist: [DayStatus: Int] = [.optimal: 0, .moderate: 0, .poor: 0, .incomplete: 0, .noData: 0]
        for day in recordedDays { statusDist[day.dayData.status, default: 0] += 1 }

        let optimalDays = statusDist[.optimal] ?? 0
        let moderateDays = statusDist[.moderate] ?? 0
        let poorDays = statusDist[.poor] ?? 0
        let incompleteDays = statusDist[.incomplete] ?? 0

        let (currentOptimalStreak, longestOptimalStreak) = calculateStreaks(in: days) { $0.status == .optimal }

        let healthScore: Double = daysTracked > 0
            ? (Double(optimalDays) * 100.0 + Double(moderateDays) * 60.0
               + Double(poorDays) * 30.0 + Double(incompleteDays) * 10.0) / Double(daysTracked)
            : 0.0

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

Cmd+B then Cmd+U. Expected: Build Succeeded, all tests pass.

---

## Task 6: Split `MainViewModelTests` into domain-focused structs

**Files:**
- Create: `HealthTrackerTests/Presentation/ViewModels/MainViewModelLoadTests.swift`
- Create: `HealthTrackerTests/Presentation/ViewModels/MainViewModelDateTests.swift`
- Create: `HealthTrackerTests/Presentation/ViewModels/MainViewModelWaterMoodTests.swift`
- Create: `HealthTrackerTests/Presentation/ViewModels/MainViewModelMealWorkoutTests.swift`
- Delete: `HealthTrackerTests/Presentation/ViewModels/MainViewModelTests.swift`

Each new file uses the same `createViewModel()` helper — copy it into each struct.

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
        let mockNotificationService = MockNotificationService()
        let viewModel = MainViewModel(
            loadUseCase: LoadDayDataUseCase(repository: mockRepository, logger: mockLogger),
            saveUseCase: SaveDayDataUseCase(repository: mockRepository, logger: mockLogger),
            cancelNotificationsUseCase: CancelNotificationsUseCase(
                notificationService: mockNotificationService, logger: mockLogger),
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

    @Test func initialization_setsDefaultState() {
        let (viewModel, _) = createViewModel()
        #expect(viewModel.days.isEmpty)
    }

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
        let mockNotificationService = MockNotificationService()
        let viewModel = MainViewModel(
            loadUseCase: LoadDayDataUseCase(repository: mockRepository, logger: mockLogger),
            saveUseCase: SaveDayDataUseCase(repository: mockRepository, logger: mockLogger),
            cancelNotificationsUseCase: CancelNotificationsUseCase(
                notificationService: mockNotificationService, logger: mockLogger),
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

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
        #expect(firstDate == day1.dayData.date)
        #expect(secondDate == day2.dayData.date)
        #expect(viewModel.currentDayData?.date == day1.dayData.date)
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
        let mockNotificationService = MockNotificationService()
        let viewModel = MainViewModel(
            loadUseCase: LoadDayDataUseCase(repository: mockRepository, logger: mockLogger),
            saveUseCase: SaveDayDataUseCase(repository: mockRepository, logger: mockLogger),
            cancelNotificationsUseCase: CancelNotificationsUseCase(
                notificationService: mockNotificationService, logger: mockLogger),
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

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
        let mockNotificationService = MockNotificationService()
        let viewModel = MainViewModel(
            loadUseCase: LoadDayDataUseCase(repository: mockRepository, logger: mockLogger),
            saveUseCase: SaveDayDataUseCase(repository: mockRepository, logger: mockLogger),
            cancelNotificationsUseCase: CancelNotificationsUseCase(
                notificationService: mockNotificationService, logger: mockLogger),
            logger: mockLogger
        )
        return (viewModel, mockRepository)
    }

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
        #expect(viewModel.meal(withId: UUID()) == nil)
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
        let original = Workout(description: "Run", duration: Workout.Duration(minutes: 30))
        viewModel.addWorkout(original)
        var updated = original
        updated.duration = Workout.Duration(minutes: 60)
        viewModel.updateWorkout(updated)
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
        #expect(viewModel.workout(withId: UUID()) == nil)
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

Cmd+B then Cmd+U. Expected: Build Succeeded, same test count as before the split.

- [ ] **Step 7: Final commit**

```bash
git add -A
git commit -m "fix: resolve batch 3 SwiftLint warnings (type_body_length, function_body_length)"
```

---

## Verification

Clean build: Cmd+Shift+K then Cmd+B. Expected: zero warnings in Issue Navigator.
