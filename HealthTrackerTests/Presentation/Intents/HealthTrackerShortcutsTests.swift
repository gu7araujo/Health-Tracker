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
        // Water, mood, meal, workout, day status (the system caps an app at 10)
        #expect(HealthTrackerShortcuts.appShortcuts.count == 5)
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
}
