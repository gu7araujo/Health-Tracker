//
//  IntentEnums.swift
//  HealthTracker
//
//  App Intents mirrors of domain enums, so the Domain layer stays framework-free.
//  Raw values are a public contract: saved Shortcuts persist them by string.
//  Never rename, renumber, or remove a shipped case — only append, adding its display entry in the same change.
//

// swiftformat:disable redundantRawValues
// swiftlint:disable redundant_string_enum_value

import AppIntents

enum MoodAppEnum: String, AppEnum {
    case good = "good"
    case neutral = "neutral"
    case sad = "sad"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "intent_type_mood"
    static let caseDisplayRepresentations: [MoodAppEnum: DisplayRepresentation] = [
        .good: "mood_good",
        .neutral: "mood_neutral",
        .sad: "mood_sad"
    ]

    var mood: Mood {
        switch self {
        case .good: .good
        case .neutral: .neutral
        case .sad: .sad
        }
    }
}

enum MealSizeAppEnum: String, AppEnum {
    case verySmall = "verySmall"
    case small = "small"
    case medium = "medium"
    case large = "large"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "intent_type_meal_size"
    static let caseDisplayRepresentations: [MealSizeAppEnum: DisplayRepresentation] = [
        .verySmall: "meal_quantity_very_small",
        .small: "meal_quantity_small",
        .medium: "meal_quantity_medium",
        .large: "meal_quantity_large"
    ]

    var quantity: Meal.Quantity {
        switch self {
        case .verySmall: .verySmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        }
    }
}

enum MealSatisfactionAppEnum: String, AppEnum {
    case thirty = "thirty"
    case fifty = "fifty"
    case eighty = "eighty"
    case hundred = "hundred"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "intent_type_meal_satisfaction"
    static let caseDisplayRepresentations: [MealSatisfactionAppEnum: DisplayRepresentation] = [
        .thirty: "satisfaction_thirty",
        .fifty: "satisfaction_fifty",
        .eighty: "satisfaction_eighty",
        .hundred: "satisfaction_hundred"
    ]

    var satisfaction: Meal.Satisfaction {
        switch self {
        case .thirty: .thirty
        case .fifty: .fifty
        case .eighty: .eighty
        case .hundred: .hundred
        }
    }
}

enum WorkoutIntensityAppEnum: String, AppEnum {
    case low = "low"
    case medium = "medium"
    case high = "high"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "intent_type_workout_intensity"
    static let caseDisplayRepresentations: [WorkoutIntensityAppEnum: DisplayRepresentation] = [
        .low: "workout_intensity_low",
        .medium: "workout_intensity_medium",
        .high: "workout_intensity_high"
    ]

    var intensity: Workout.Intensity {
        switch self {
        case .low: .low
        case .medium: .medium
        case .high: .high
        }
    }
}

// swiftlint:enable redundant_string_enum_value
// swiftformat:enable redundantRawValues
