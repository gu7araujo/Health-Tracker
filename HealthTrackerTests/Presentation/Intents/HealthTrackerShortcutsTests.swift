//
//  HealthTrackerShortcutsTests.swift
//  HealthTrackerTests
//

import AppIntents
@testable import HealthTracker
import Testing

@MainActor
struct HealthTrackerShortcutsTests {
    @Test func appShortcuts_registersOneShortcutPerIntent() {
        // Water, meal, mood, workout, day status (the system caps an app at 10)
        #expect(HealthTrackerShortcuts.appShortcuts.count == 5)
    }

    /// Spotlight starts from this order when people search the app's name, and only a few fit.
    @Test func appShortcuts_leadWithTheMostCommonLogs() {
        let titles = HealthTrackerShortcuts.appShortcuts.map {
            (field("shortTitle", of: $0) as LocalizedStringResource?)?.key
        }

        #expect(titles == [
            "intent_log_water_title", "intent_add_meal_title", "intent_log_mood_title",
            "intent_add_workout_title", "intent_day_status_title"
        ])
    }

    /// A phrase that interpolates an `AppEnum` becomes one Spotlight result per case,
    /// crowding the other shortcuts out of the few slots an app-name search shows.
    @Test func appShortcuts_haveNoPerCasePhrases() {
        let templates = HealthTrackerShortcuts.appShortcuts.flatMap {
            (field("basePhraseTemplates", of: $0) as [String]?) ?? []
        }

        #expect(templates.count == 7)
        let parameters = templates.map { $0.replacingOccurrences(of: "${applicationName}", with: "") }
        #expect(parameters.allSatisfy { !$0.contains("${") })
    }

    /// Read through the protocol, as the system does: a non-optional `static let description`
    /// doesn't witness `IntentDescription?`, leaving the default `nil`.
    @Test(arguments: [
        LogWaterIntent.self, LogMoodIntent.self, AddMealIntent.self,
        AddWorkoutIntent.self, GetDayStatusIntent.self
    ] as [any AppIntent.Type])
    func intent_providesDescriptionToTheSystem(intent: any AppIntent.Type) {
        #expect(intent.description != nil)
    }

    /// `AppShortcut` exposes nothing publicly, so these read its stored fields by name.
    private func field<T>(_ name: String, of shortcut: AppShortcut) -> T? {
        Mirror(reflecting: shortcut).children.first { $0.label == name }?.value as? T
    }
}
