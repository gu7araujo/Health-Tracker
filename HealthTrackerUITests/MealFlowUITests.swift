//
//  MealFlowUITests.swift
//  HealthTrackerUITests
//

import XCTest

final class MealFlowUITests: HealthTrackerUITestCase {
    func testAddMealSingleItem() {
        addMeal(items: ["Oatmeal"])
        let card = assertExists(element(AccessibilityID.mealCard(0)))
        XCTAssertTrue(card.label.contains("Oatmeal"))
        XCTAssertTrue(card.label.contains("Quantity: Small"))
        XCTAssertTrue(card.label.contains("Satisfied: 50%"))
    }

    func testAddMealMultipleItemsWithPickers() {
        addMeal(items: ["Rice", "Beans", "Salad"], quantity: EnglishLabel.quantityLarge)
        let card = assertExists(element(AccessibilityID.mealCard(0)))
        XCTAssertTrue(card.label.contains("Rice, Beans, Salad"))
        XCTAssertTrue(card.label.contains("Quantity: Large"))
        // Choosing Large auto-updates satisfaction to its default of 100%
        XCTAssertTrue(card.label.contains("Satisfied: 100%"))
    }

    func testRemoveMealItemField() {
        openAddModal(choosing: EnglishLabel.mealOption)
        let firstField = assertExists(app.textFields[AccessibilityID.mealItemField(0)])
        firstField.tap()
        firstField.typeText("Soup")

        assertExists(app.buttons[AccessibilityID.addMealItemButton]).tap()
        assertExists(app.textFields[AccessibilityID.mealItemField(1)])
        assertExists(app.buttons[AccessibilityID.mealItemDeleteButton(1)]).tap()
        assertNotExists(app.textFields[AccessibilityID.mealItemField(1)], timeout: 2)

        saveModal()
        XCTAssertTrue(assertExists(element(AccessibilityID.mealCard(0))).label.contains("Soup"))
    }

    func testMealItemLimitOfFive() {
        openAddModal(choosing: EnglishLabel.mealOption)
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
        cancelModal()
    }

    func testEditMealUpdatesCard() {
        addMeal(items: ["Toast"])
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
        XCTAssertTrue(card.label.contains("Satisfied: 80%"))
    }

    func testDeleteMealShowsEmptyState() {
        addMeal(items: ["Pasta"])
        tapSwipeAction(
            on: element(AccessibilityID.mealCard(0)),
            identifier: AccessibilityID.mealDeleteButton(0),
            fallbackLabel: EnglishLabel.deleteAction
        )
        assertNotExists(element(AccessibilityID.mealCard(0)))
        assertExists(element(AccessibilityID.mealsEmptyState))
    }

    func testCancelDiscardsInput() {
        openAddModal(choosing: EnglishLabel.mealOption)
        let field = assertExists(app.textFields[AccessibilityID.mealItemField(0)])
        field.tap()
        field.typeText("Discarded")
        cancelModal()

        assertExists(element(AccessibilityID.mealsEmptyState))
        assertNotExists(element(AccessibilityID.mealCard(0)), timeout: 2)
    }
}
