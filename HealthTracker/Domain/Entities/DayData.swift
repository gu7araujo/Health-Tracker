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
    var id: Date {
        date
    }

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

        // Incomplete: only 1 category has data
        guard categoriesCount >= 2 else { return .incomplete }

        // 2-4 categories have data: evaluate status
        // Poor is checked first — any poor signal always wins
        if meetsPoorCriteria { return .poor }

        if meetsOptimalCriteria { return .optimal }

        if meetsModerateCriteria { return .moderate }

        // Fallback: has data but doesn't meet any specific criteria
        return .poor
    }

    /// Generates a localized explanation of why the day received its status.
    /// Returns nil for .noData and .incomplete statuses.
    var statusExplanation: String? {
        let currentStatus = status

        // No explanation for incomplete or no data
        guard currentStatus != .noData && currentStatus != .incomplete else {
            return nil
        }

        // Optimal status - all targets met
        if currentStatus == .optimal {
            return NSLocalizedString("day_status_explanation.optimal", comment: "")
        }

        // Collect reasons for moderate or poor status
        var reasons: [String] = []

        // Check meal issues
        let mediumMealCount = meals.filter { $0.quantity == .medium }.count
        let hasLargeMeal = meals.contains { $0.quantity == .large }

        if mediumMealCount >= 3 || hasLargeMeal {
            reasons.append(NSLocalizedString("day_status_reason.meals_multiple_medium", comment: ""))
        } else if mediumMealCount == 2 {
            reasons.append(NSLocalizedString("day_status_reason.meals_two_medium", comment: ""))
        }

        // Check water issues
        let waterAmount = water ?? 0
        if waterAmount < 1.0 {
            if waterAmount == 0 {
                reasons.append(NSLocalizedString("day_status_reason.water_none", comment: ""))
            } else {
                reasons.append(NSLocalizedString("day_status_reason.water_low", comment: ""))
            }
        } else if waterAmount >= 1.0, waterAmount < 1.8 {
            reasons.append(NSLocalizedString("day_status_reason.water_moderate", comment: ""))
        }

        // Check workout issues
        if totalWorkoutDuration == 0 {
            reasons.append(NSLocalizedString("day_status_reason.workout_none", comment: ""))
        } else if totalWorkoutDuration < 30 {
            reasons.append(NSLocalizedString("day_status_reason.workout_insufficient", comment: ""))
        }

        // Check mood issues
        if mood == .neutral {
            reasons.append(NSLocalizedString("day_status_reason.mood_neutral", comment: ""))
        } else if mood == .sad {
            reasons.append(NSLocalizedString("day_status_reason.mood_sad", comment: ""))
        }

        // Build final explanation
        let header = currentStatus == .moderate
            ? NSLocalizedString("day_status_explanation.moderate", comment: "")
            : NSLocalizedString("day_status_explanation.poor", comment: "")

        guard !reasons.isEmpty else {
            return header + "."
        }

        return "\(header): \(reasons.joined(separator: ", "))."
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

    /// Computes the total workout duration for this day in minutes.
    private var totalWorkoutDuration: Int {
        workouts.reduce(0) { $0 + $1.duration.minutes }
    }

    /// Checks if all optimal (green) criteria are met.
    /// Requirements:
    /// - Meals: Only verySmall/small OR at most 1 medium meal (satiety ignored)
    /// - Water: >= 1.8L
    /// - Workouts: Total duration >= 30 minutes
    /// - Mood: good
    private var meetsOptimalCriteria: Bool {
        guard !meals.isEmpty else { return false }

        // Count medium meals (satiety ignored)
        let mediumMealCount = meals.filter { $0.quantity == .medium }.count
        let smallMealCount = meals.filter { $0.quantity == .small || $0.quantity == .verySmall }.count

        // Allow only small/verySmall meals OR at most 1 medium meal (rest must be small/verySmall)
        let hasOptimalMeals = mediumMealCount <= 1 && (mediumMealCount + smallMealCount) == meals.count

        let hasOptimalWater = (water ?? 0) >= 1.8
        let hasOptimalWorkouts = totalWorkoutDuration >= 30
        let hasGoodMood = mood == .good

        return hasOptimalMeals && hasOptimalWater && hasOptimalWorkouts && hasGoodMood
    }

    /// Checks if any moderate (yellow) criteria are met.
    /// Requirements (ANY one of):
    /// - Meals: Exactly 2 medium meals (satiety ignored)
    /// - Water: >= 1.0L AND < 1.8L
    /// - Workouts: Total duration < 30 min
    /// - Mood: neutral
    private var meetsModerateCriteria: Bool {
        let mediumMealCount = meals.filter { $0.quantity == .medium }.count
        let hasModerateMeals = mediumMealCount == 2

        let waterAmount = water ?? 0
        let hasModerateWater = waterAmount >= 1.0 && waterAmount < 1.8

        let hasModerateWorkouts = totalWorkoutDuration < 30

        let hasNeutralMood = mood == .neutral

        return hasModerateMeals || hasModerateWater || hasModerateWorkouts || hasNeutralMood
    }

    /// Checks if any poor (red) criteria are met.
    /// Requirements (ANY one of):
    /// - Meals: 3+ medium meals OR any large meal (satiety ignored)
    /// - Water: < 1.0L (or nil)
    /// - Mood: sad
    /// Note: Workouts don't affect poor status
    private var meetsPoorCriteria: Bool {
        let mediumMealCount = meals.filter { $0.quantity == .medium }.count
        let hasLargeMeal = meals.contains { $0.quantity == .large }
        let poorMeals = mediumMealCount >= 3 || hasLargeMeal

        let lowWater = (water ?? 0) < 1.0
        let badMood = mood == .sad

        return poorMeals || lowWater || badMood
    }
}

/// Represents the type of health tracking section (meal or workout)
enum HealthSection: Equatable, Hashable, Identifiable {
    case meal
    case workout

    var id: Self {
        self
    }
}
