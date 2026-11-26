//
//  MealFlowUITests.swift
//  HealthTrackerUITests
//

import XCTest

final class MealFlowUITests: HealthTrackerUITestCase {
    func testMealAddEditDelete() {
        XCTContext.runActivity(named: "Add") { _ in
            addMeal(items: ["Oatmeal"])
            let card = assertExists(element(AccessibilityID.mealCard(0)))
            XCTAssertTrue(card.label.contains("Oatmeal"))
            XCTAssertTrue(card.label.contains("Size: Small"))
            XCTAssertTrue(card.label.contains("Satisfaction: 50%"))
        }

        XCTContext.runActivity(named: "Edit") { _ in
            tapSwipeAction(
                on: element(AccessibilityID.mealCard(0)),
                identifier: AccessibilityID.mealEditButton(0),
                fallbackLabel: EnglishLabel.editAction
            )
            let field = assertExists(app.textFields[AccessibilityID.mealItemField(0)])
            clearAndType(field, with: "Toast with eggs")
            selectMenuOption(picker: AccessibilityID.satisfactionPicker, option: EnglishLabel.satisfactionEighty)
            saveModal()

            let card = assertExists(element(AccessibilityID.mealCard(0)))
            XCTAssertTrue(card.label.contains("Toast with eggs"))
            XCTAssertTrue(card.label.contains("Satisfaction: 80%"))
        }

        XCTContext.runActivity(named: "Delete") { _ in
            tapSwipeAction(
                on: element(AccessibilityID.mealCard(0)),
                identifier: AccessibilityID.mealDeleteButton(0),
                fallbackLabel: EnglishLabel.deleteAction
            )
            assertNotExists(element(AccessibilityID.mealCard(0)))
            assertExists(element(AccessibilityID.mealsEmptyState))
        }
    }

    /// Taps once the element is hittable: the keyboard that Add item raises resizes the sheet, and a
    /// tap during that resize finds the button "not hittable".
    private func tapWhenHittable(_ element: XCUIElement) {
        let element = assertExists(element)
        XCTAssertTrue(waitUntil { element.isHittable }, "Expected element to be hittable: \(element)")
        element.tap()
    }

    func testMealMultipleItemsAndFieldRemoval() {
        openAddModal(choosing: EnglishLabel.mealOption)
        let addItemButton = app.buttons[AccessibilityID.addMealItemButton]

        XCTContext.runActivity(named: "Remove a field") { _ in
            enterText("Rice", into: assertExists(app.textFields[AccessibilityID.mealItemField(0)]))

            assertExists(addItemButton).tap()
            // The new field takes the keyboard so the user can type the next item straight away
            assertKeyboardFocus(assertExists(app.textFields[AccessibilityID.mealItemField(1)]))
            tapWhenHittable(app.buttons[AccessibilityID.mealItemDeleteButton(1)])
            assertNotExists(app.textFields[AccessibilityID.mealItemField(1)], timeout: 2)
        }

        XCTContext.runActivity(named: "Save several items with Large") { _ in
            for (index, item) in ["Beans", "Discarded", "Salad"].enumerated() {
                assertExists(addItemButton).tap()
                enterText(item, into: assertExists(app.textFields[AccessibilityID.mealItemField(index + 1)]))
            }
            // Removing an earlier field keeps the keyboard on Salad, which moves up one row
            tapWhenHittable(app.buttons[AccessibilityID.mealItemDeleteButton(2)])
            let salad = app.textFields[AccessibilityID.mealItemField(2)]
            assertKeyboardFocus(salad)
            XCTAssertEqual(salad.value as? String, "Salad")
            selectMenuOption(picker: AccessibilityID.quantityPicker, option: EnglishLabel.quantityLarge)
            saveModal()

            let card = assertExists(element(AccessibilityID.mealCard(0)))
            XCTAssertTrue(card.label.contains("Rice, Beans, Salad"))
            XCTAssertTrue(card.label.contains("Size: Large"))
            // Choosing Large auto-updates satisfaction to its default of 100%
            XCTAssertTrue(card.label.contains("Satisfaction: 100%"))
        }
    }

    func testMealItemLimitAndCancel() {
        openAddModal(choosing: EnglishLabel.mealOption)

        XCTContext.runActivity(named: "Grow to five fields") { _ in
            enterText("Discarded", into: assertExists(app.textFields[AccessibilityID.mealItemField(0)]))

            let addButton = app.buttons[AccessibilityID.addMealItemButton]
            let modalList = element(AccessibilityID.modalList)
            for index in 1 ... 4 {
                // The growing field list pushes the button past the sheet's bottom edge, where
                // it still reports hittable but taps land dead — scroll before every tap
                modalList.swipeUp()
                assertExists(addButton).tap()
                assertExists(app.textFields[AccessibilityID.mealItemField(index)])
            }
            assertNotExists(addButton, timeout: 2)
        }

        XCTContext.runActivity(named: "Cancel") { _ in
            cancelModal()
            assertExists(element(AccessibilityID.mealsEmptyState))
            assertNotExists(element(AccessibilityID.mealCard(0)), timeout: 2)
        }
    }
}
