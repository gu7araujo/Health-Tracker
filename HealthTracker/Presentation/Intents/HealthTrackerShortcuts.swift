//
//  HealthTrackerShortcuts.swift
//  HealthTracker
//
//  Zero-setup Siri, Spotlight, and Action button entry points (5 of the 10 allowed).
//  Phrases are a public contract once shipped: add new ones, never rename or remove.
//  Each phrase needs `\(.applicationName)`, and its translations live in `AppShortcuts.strings`.
//

import AppIntents

struct HealthTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "I drank water in \(.applicationName)"
            ],
            shortTitle: "intent_log_water_title",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: LogMoodIntent(),
            phrases: [
                "I'm feeling \(\.$mood) in \(.applicationName)",
                "Log my mood in \(.applicationName)"
            ],
            shortTitle: "intent_log_mood_title",
            systemImageName: "face.smiling"
        )
        AppShortcut(
            intent: AddMealIntent(),
            phrases: ["Log a meal in \(.applicationName)"],
            shortTitle: "intent_add_meal_title",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: AddWorkoutIntent(),
            phrases: ["Log a workout in \(.applicationName)"],
            shortTitle: "intent_add_workout_title",
            systemImageName: "figure.run"
        )
        AppShortcut(
            intent: GetDayStatusIntent(),
            phrases: [
                "How's my day in \(.applicationName)",
                "My status in \(.applicationName)"
            ],
            shortTitle: "intent_day_status_title",
            systemImageName: "heart.text.square"
        )
    }
}
