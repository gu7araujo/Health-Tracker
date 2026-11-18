//
//  WorkoutFlowUITests.swift
//  HealthTrackerUITests
//

import XCTest

final class WorkoutFlowUITests: HealthTrackerUITestCase {
    func testWorkoutAddEditDelete() {
        XCTContext.runActivity(named: "Add") { _ in
            addWorkout(description: "Run")
            let card = assertExists(element(AccessibilityID.workoutCard(0)))
            XCTAssertTrue(card.label.contains("Run"))
            XCTAssertTrue(card.label.contains("Time: 30m"))
            // Intensity defaults to Medium and is shown on the card
            XCTAssertTrue(card.label.contains("Intensity: Medium"))
        }

        XCTContext.runActivity(named: "Edit") { _ in
            tapSwipeAction(
                on: element(AccessibilityID.workoutCard(0)),
                identifier: AccessibilityID.workoutEditButton(0),
                fallbackLabel: EnglishLabel.editAction
            )
            let field = assertExists(app.textFields[AccessibilityID.workoutDescriptionField])
            clearAndType(field, with: "Long walk")
            setDurationWheels(hours: nil, minutes: 45)
            saveModal()

            let card = assertExists(element(AccessibilityID.workoutCard(0)))
            XCTAssertTrue(card.label.contains("Long walk"))
            XCTAssertTrue(card.label.contains("Time: 45m"))
        }

        XCTContext.runActivity(named: "Delete") { _ in
            tapSwipeAction(
                on: element(AccessibilityID.workoutCard(0)),
                identifier: AccessibilityID.workoutDeleteButton(0),
                fallbackLabel: EnglishLabel.deleteAction
            )
            assertNotExists(element(AccessibilityID.workoutCard(0)))
            assertExists(element(AccessibilityID.workoutsEmptyState))
        }
    }

    func testAddWorkoutWithWheelDurationAndIntensity() {
        addWorkout(description: "Bike", hours: 1, minutes: 15, intensity: EnglishLabel.intensityHigh)
        let card = assertExists(element(AccessibilityID.workoutCard(0)))
        XCTAssertTrue(card.label.contains("Bike"))
        XCTAssertTrue(card.label.contains("Time: 1h15m"))
        XCTAssertTrue(card.label.contains("Intensity: High"))
    }
}
