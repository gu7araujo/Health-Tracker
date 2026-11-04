//
//  AddWorkoutIntent.swift
//  HealthTracker
//

import AppIntents
import Foundation

/// Appends a workout to today from Siri, Shortcuts, or Spotlight.
/// The type name is a public contract: saved Shortcuts replay the intent by it.
struct AddWorkoutIntent: AppIntent, UndoableIntent {
    static let title: LocalizedStringResource = "intent_add_workout_title"
    static let description: IntentDescription? = IntentDescription("intent_add_workout_description")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "intent_param_workout_name", requestValueDialog: IntentDialog(AddWorkoutIntent.namePrompt))
    var name: String

    /// Same 1–300 range `Workout.Duration` clamps to.
    @Parameter(title: "intent_param_workout_minutes", default: 30, inclusiveRange: (1, 300))
    var minutes: Int

    @Parameter(title: "intent_param_workout_intensity", default: .medium)
    var intensity: WorkoutIntensityAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("intent_add_workout_summary \(\.$name)") {
            \.$minutes
            \.$intensity
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let useCase = IntentUseCaseFactory.makeUpdateDayDataUseCase()
        let change = try run(with: useCase, on: .now)
        registerUndo(on: undoManager, useCase: useCase, change: change)
        await IntentUseCaseFactory.cancelTodaysNotifications()
        return .result(dialog: IntentDialog(Self.dialog(for: change.after.workouts.last?.description ?? "")))
    }

    /// Resolved in the app, so Siri and Shortcuts read it in the app's language (see `resolvedInApp`).
    static var namePrompt: LocalizedStringResource {
        LocalizedStringResource("intent_param_workout_name_prompt").resolvedInApp
    }

    static func dialog(for workout: String) -> LocalizedStringResource {
        LocalizedStringResource("intent_add_workout_dialog \(workout)").resolvedInApp
    }

    /// The intent's single write. A blank name re-asks before anything is saved, so the restart can't double-log.
    @MainActor
    @discardableResult
    func run(with useCase: UpdateDayDataUseCase, on date: Date) throws -> DayDataChange {
        let description = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !description.isEmpty else {
            throw $name.needsValueError(IntentDialog(Self.namePrompt))
        }
        let workout = Workout(
            description: description,
            duration: Workout.Duration(minutes: minutes),
            intensity: intensity.intensity
        )
        return useCase.executeAndNotify(for: date) { $0.addWorkout(workout) }
    }

    /// Removes only the workout this intent added, by id, leaving workouts logged since untouched.
    @MainActor
    func registerUndo(on undoManager: UndoManager?, useCase: UpdateDayDataUseCase, change: DayDataChange) {
        guard let workout = change.after.workouts.last else { return }
        useCase.registerUndo(on: undoManager, for: change.after.date) { $0.removeWorkout(id: workout.id) }
    }
}
