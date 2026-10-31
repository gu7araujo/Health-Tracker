//
//  LogWaterIntent.swift
//  HealthTracker
//

import AppIntents
import Foundation

/// Adds an amount of water to today's total from Siri, Shortcuts, or Spotlight.
/// The type name is a public contract: saved Shortcuts replay the intent by it.
struct LogWaterIntent: AppIntent, UndoableIntent {
    static let title: LocalizedStringResource = "intent_log_water_title"
    static let description: IntentDescription? = IntentDescription("intent_log_water_description")
    static let supportedModes: IntentModes = .background

    @Parameter(
        title: "intent_param_water_amount",
        defaultValue: 250,
        defaultUnit: .milliliters,
        supportsNegativeNumbers: false
    )
    var amount: Measurement<UnitVolume>

    static var parameterSummary: some ParameterSummary {
        Summary("intent_log_water_summary \(\.$amount)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let useCase = IntentUseCaseFactory.makeUpdateDayDataUseCase()
        let change = try run(with: useCase, on: .now)
        registerUndo(on: undoManager, useCase: useCase, change: change)
        await IntentUseCaseFactory.cancelTodaysNotifications()
        return .result(dialog: "intent_log_water_dialog \(Self.formatted(change.after.water ?? 0))")
    }

    /// The intent's single write; everything it needs is resolved before it runs, so a restart can't double-log.
    /// Throws, having written nothing, when clamping leaves nothing to add (0 mL, or the 5 L max reached).
    @MainActor
    @discardableResult
    func run(with useCase: UpdateDayDataUseCase, on date: Date) throws -> DayDataChange {
        let liters = amount.converted(to: .liters).value
        let change = useCase.executeAndNotify(for: date) { $0.addWater(liters: liters) }
        guard change.after != change.before else { throw NothingAddedError(total: change.after.water ?? 0) }
        return change
    }

    /// Takes back only what this intent added (after clamping), so water logged since is kept.
    @MainActor
    func registerUndo(on undoManager: UndoManager?, useCase: UpdateDayDataUseCase, change: DayDataChange) {
        let added = (change.after.water ?? 0) - (change.before.water ?? 0)
        useCase.registerUndo(on: undoManager, for: change.after.date) { $0.addWater(liters: -added) }
    }

    /// Tells the person nothing was logged, rather than reporting a total that didn't move.
    struct NothingAddedError: Error, CustomLocalizedStringResourceConvertible {
        let total: Double

        var localizedStringResource: LocalizedStringResource {
            "intent_log_water_nothing_added \(LogWaterIntent.formatted(total))"
        }
    }

    private static func formatted(_ liters: Double) -> String {
        liters.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
}
