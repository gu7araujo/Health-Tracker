//
//  GetDayStatusIntent.swift
//  HealthTracker
//

import AppIntents
import Foundation

/// Read-only: speaks today's status and why, and returns the text so other Shortcuts can use it.
/// The type name is a public contract: saved Shortcuts replay the intent by it.
struct GetDayStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "intent_day_status_title"
    static let description: IntentDescription? = IntentDescription("intent_day_status_description")
    static let supportedModes: IntentModes = .background

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let text = run(with: IntentUseCaseFactory.makeLoadDayDataUseCase(), on: .now)
        return .result(value: text, dialog: "\(text)")
    }

    /// The day's status explanation, or its own line for days too empty to have one.
    @MainActor
    func run(with useCase: LoadDayDataUseCase, on date: Date) -> String {
        let day = useCase.execute(for: date)
        switch day.status {
        case .noData: return String(localized: "intent_day_status_no_data")
        case .incomplete: return String(localized: "intent_day_status_incomplete")
        case .optimal, .moderate, .poor: return day.statusExplanation ?? ""
        }
    }
}
