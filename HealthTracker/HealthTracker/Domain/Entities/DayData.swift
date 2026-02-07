//
//  DayData.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on 10/18/25.
//

import Foundation

/// Represents all health tracking data for a single day.
/// This is the main aggregate entity that holds meals, workouts, water intake, and mood.
struct DayData: Codable, Equatable, Identifiable {
    var id: Date { date }

    let date: Date
    var meals: [Meal]
    var workouts: [Workout]
    var water: Double?
    var mood: Mood?

    init(
        date: Date,
        meals: [Meal] = [],
        workouts: [Workout] = [],
        water: Double? = nil,
        mood: Mood? = nil
    ) {
        self.date = date
        self.meals = meals
        self.workouts = workouts
        self.water = water
        self.mood = mood
    }

    // MARK: - Meal Operations

    mutating func addMeal(_ meal: Meal) {
        meals.append(meal)
    }

    mutating func updateMeal(_ meal: Meal) {
        guard let index = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        meals[index] = meal
    }

    mutating func removeMeal(id: UUID) {
        meals.removeAll { $0.id == id }
    }

    // MARK: - Workout Operations

    mutating func addWorkout(_ workout: Workout) {
        workouts.append(workout)
    }

    mutating func updateWorkout(_ workout: Workout) {
        guard let index = workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        workouts[index] = workout
    }

    mutating func removeWorkout(id: UUID) {
        workouts.removeAll { $0.id == id }
    }

    // MARK: - Status Computation

    /// Computes the health status for this day based on meals, water, workouts, and mood.
    var status: DayStatus {
        let categoriesCount = filledCategoriesCount

        // No data recorded
        guard categoriesCount > 0 else { return .noData }

        // Incomplete: only 1-2 categories have data
        guard categoriesCount >= 3 else { return .incomplete }

        // 3-4 categories have data: evaluate status
        if meetsOptimalCriteria { return .optimal }

        if meetsModerateCriteria { return .moderate }

        return .poor
    }

    /// Counts how many of the 4 categories (meals, water, workouts, mood) have data.
    private var filledCategoriesCount: Int {
        var count = 0
        if !meals.isEmpty { count += 1 }
        if water != nil { count += 1 }
        if !workouts.isEmpty { count += 1 }
        if mood != nil { count += 1 }
        return count
    }

    /// Checks if all optimal (green) criteria are met.
    /// Requirements: all meals small/verySmall + 50% satiety, water >= 1.8L, has workout, good mood
    private var meetsOptimalCriteria: Bool {
        let hasOptimalMeals = !meals.isEmpty && meals.allSatisfy { meal in
            (meal.quantity == .small || meal.quantity == .verySmall) && meal.satisfaction == .fifty
        }
        let hasOptimalWater = (water ?? 0) >= 1.8
        let hasWorkout = !workouts.isEmpty
        let hasGoodMood = mood == .good

        return hasOptimalMeals && hasOptimalWater && hasWorkout && hasGoodMood
    }

    /// Checks if any moderate (yellow) criteria are met.
    /// Requirements: 1-2 meals with medium + 80% satiety, OR water 1.0-1.7L, OR neutral mood
    private var meetsModerateCriteria: Bool {
        let moderateMealCount = meals.filter { meal in
            meal.quantity == .medium && meal.satisfaction == .eighty
        }.count
        let hasModerateMeals = moderateMealCount >= 1 && moderateMealCount <= 2

        let waterAmount = water ?? 0
        let hasModerateWater = waterAmount >= 1.0 && waterAmount < 1.8

        let hasNeutralMood = mood == .neutral

        return hasModerateMeals || hasModerateWater || hasNeutralMood
    }
}

/// Represents the type of health tracking section (meal or workout)
enum HealthSection: Equatable, Hashable, Identifiable {
    case meal
    case workout

    var id: Self { self }
}
