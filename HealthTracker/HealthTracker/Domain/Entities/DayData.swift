//
//  DayData.swift
//  HealthTracker
//
//  Domain Entity - Pure Swift
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
}

/// Represents the type of health tracking section (meal or workout)
enum HealthSection: Equatable {
    case meal
    case workout
}
