//
//  EnglishLabel.swift
//  HealthTrackerUITests
//
//  English display labels for elements that cannot carry accessibility identifiers
//  (alert buttons, menu picker options). Tests force English via launch arguments,
//  so these values must match HealthTracker/Resources/en.lproj/Localizable.strings.
//

enum EnglishLabel {
    // Add record alert
    static let mealOption = "Meal"
    static let workoutOption = "Workout"
    static let cancel = "Cancel"

    // Quantity picker options
    static let quantityVerySmall = "Very Small"
    static let quantitySmall = "Small"
    static let quantityMedium = "Medium"
    static let quantityLarge = "Large"

    // Satisfaction picker options
    static let satisfactionThirty = "30%"
    static let satisfactionFifty = "50%"
    static let satisfactionEighty = "80%"
    static let satisfactionHundred = "100%"

    // Intensity picker options
    static let intensityLow = "Low"
    static let intensityMedium = "Medium"
    static let intensityHigh = "High"

    // Swipe actions
    static let deleteAction = "Delete"
    static let editAction = "Edit"
}
