//
//  AccessibilityID.swift
//  HealthTrackerUITests
//
//  Keep in sync with HealthTracker/Presentation/AccessibilityID.swift
//

import Foundation

/// Accessibility identifiers mirrored from the app target (UI tests cannot import app types).
enum AccessibilityID {
    // MARK: - Main Screen

    static let addRecordButton = "addRecordButton"
    static let waterSlider = "waterSlider"
    static let waterValueLabel = "waterValueLabel"
    static let mealsEmptyState = "mealsEmptyState"
    static let workoutsEmptyState = "workoutsEmptyState"
    static let moodButtonGood = "moodButton_good"
    static let moodButtonNeutral = "moodButton_neutral"
    static let moodButtonSad = "moodButton_sad"

    /// Calendar day cell identified by its offset in days from today (-1 yesterday, 0 today, 1 tomorrow).
    static func calendarDay(offset: Int) -> String {
        "calendarDay_\(offset)"
    }

    static func mealCard(_ index: Int) -> String {
        "mealCard_\(index)"
    }

    static func mealEditButton(_ index: Int) -> String {
        "mealEditButton_\(index)"
    }

    static func mealDeleteButton(_ index: Int) -> String {
        "mealDeleteButton_\(index)"
    }

    static func workoutCard(_ index: Int) -> String {
        "workoutCard_\(index)"
    }

    static func workoutEditButton(_ index: Int) -> String {
        "workoutEditButton_\(index)"
    }

    static func workoutDeleteButton(_ index: Int) -> String {
        "workoutDeleteButton_\(index)"
    }

    // MARK: - Add/Edit Modal

    static let modalList = "addEditModalList"
    static let modalSaveButton = "modalSaveButton"
    static let modalCancelButton = "modalCancelButton"
    static let addMealItemButton = "addMealItemButton"
    static let quantityPicker = "quantityPicker"
    static let satisfactionPicker = "satisfactionPicker"
    static let workoutDescriptionField = "workoutDescriptionField"
    static let durationPicker = "durationPicker"
    static let intensityPicker = "intensityPicker"

    static func mealItemField(_ index: Int) -> String {
        "mealItemField_\(index)"
    }

    static func mealItemDeleteButton(_ index: Int) -> String {
        "mealItemDeleteButton_\(index)"
    }
}
