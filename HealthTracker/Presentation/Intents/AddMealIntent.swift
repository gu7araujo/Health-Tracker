//
//  AddMealIntent.swift
//  HealthTracker
//

import AppIntents
import Foundation

/// Appends a meal to today from Siri, Shortcuts, or Spotlight.
/// The type name is a public contract: saved Shortcuts replay the intent by it.
struct AddMealIntent: AppIntent, UndoableIntent {
    static let title: LocalizedStringResource = "intent_add_meal_title"
    static let description: IntentDescription? = IntentDescription("intent_add_meal_description")
    static let supportedModes: IntentModes = .background

    /// Comma-separated, like the items typed in the add-meal modal.
    @Parameter(title: "intent_param_meal_items", requestValueDialog: IntentDialog(AddMealIntent.itemsPrompt))
    var items: String

    @Parameter(title: "intent_param_meal_size", default: .small)
    var size: MealSizeAppEnum

    /// When omitted, follows the size's default, as the add-meal modal does.
    @Parameter(title: "intent_param_meal_satisfaction")
    var satisfaction: MealSatisfactionAppEnum?

    static var parameterSummary: some ParameterSummary {
        Summary("intent_add_meal_summary \(\.$items)") {
            \.$size
            \.$satisfaction
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let useCase = IntentUseCaseFactory.makeUpdateDayDataUseCase()
        let change = try run(with: useCase, on: .now)
        registerUndo(on: undoManager, useCase: useCase, change: change)
        await IntentUseCaseFactory.cancelTodaysNotifications()
        return .result(dialog: IntentDialog(Self.dialog(for: change.after.meals.last?.description ?? "")))
    }

    /// Resolved in the app, so Siri and Shortcuts read it in the app's language (see `resolvedInApp`).
    static var itemsPrompt: LocalizedStringResource {
        LocalizedStringResource("intent_param_meal_items_prompt").resolvedInApp
    }

    static func dialog(for meal: String) -> LocalizedStringResource {
        LocalizedStringResource("intent_add_meal_dialog \(meal)").resolvedInApp
    }

    /// The intent's single write. Blank items re-ask before anything is saved, so the restart can't double-log.
    @MainActor
    @discardableResult
    func run(with useCase: UpdateDayDataUseCase, on date: Date) throws -> DayDataChange {
        let parsedItems = items.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !parsedItems.isEmpty else {
            throw $items.needsValueError(IntentDialog(Self.itemsPrompt))
        }
        let quantity = size.quantity
        let meal = Meal(
            items: parsedItems,
            quantity: quantity,
            satisfaction: satisfaction?.satisfaction ?? quantity.defaultSatisfaction
        )
        return useCase.executeAndNotify(for: date) { $0.addMeal(meal) }
    }

    /// Removes only the meal this intent added, by id, leaving meals logged since untouched.
    @MainActor
    func registerUndo(on undoManager: UndoManager?, useCase: UpdateDayDataUseCase, change: DayDataChange) {
        guard let meal = change.after.meals.last else { return }
        useCase.registerUndo(on: undoManager, for: change.after.date) { $0.removeMeal(id: meal.id) }
    }
}
