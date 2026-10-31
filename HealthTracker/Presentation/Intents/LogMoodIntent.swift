//
//  LogMoodIntent.swift
//  HealthTracker
//

import AppIntents
import Foundation

/// Sets today's mood from Siri, Shortcuts, or Spotlight.
/// The type name is a public contract: saved Shortcuts replay the intent by it.
struct LogMoodIntent: AppIntent, UndoableIntent {
    static let title: LocalizedStringResource = "intent_log_mood_title"
    static let description: IntentDescription? = IntentDescription("intent_log_mood_description")
    static let supportedModes: IntentModes = .background

    @Parameter(title: "intent_param_mood", requestDisambiguationDialog: "intent_param_mood_prompt")
    var mood: MoodAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("intent_log_mood_summary \(\.$mood)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let useCase = IntentUseCaseFactory.makeUpdateDayDataUseCase()
        let change = run(with: useCase, on: .now)
        registerUndo(on: undoManager, useCase: useCase, change: change)
        await IntentUseCaseFactory.cancelTodaysNotifications()
        return .result(dialog: "intent_log_mood_dialog \(mood.mood.localizedName)")
    }

    /// The intent's single write; everything it needs is resolved before it runs, so a restart can't double-log.
    @MainActor
    @discardableResult
    func run(with useCase: UpdateDayDataUseCase, on date: Date) -> DayDataChange {
        let mood = mood.mood
        return useCase.executeAndNotify(for: date) { $0.mood = mood }
    }

    /// Restores the previous mood (or none) only if this intent's mood is still set, so a later choice is kept.
    @MainActor
    func registerUndo(on undoManager: UndoManager?, useCase: UpdateDayDataUseCase, change: DayDataChange) {
        useCase.registerUndo(on: undoManager, for: change.after.date) {
            if $0.mood == change.after.mood { $0.mood = change.before.mood }
        }
    }
}
