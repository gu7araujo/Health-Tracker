//
//  AppIntentsUITests.swift
//  HealthTrackerIntentsUITests
//

import AppIntentsTesting
import XCTest

/// Runs the App Intents the way Siri and Shortcuts do: out of process, through `AppIntentsTesting`,
/// inside the app `setUp` launched with `-uiTesting`, so they share its isolated store.
/// Intents, enums, and raw values are addressed by their persisted names, so a rename fails here first.
final class AppIntentsUITests: HealthTrackerUITestCase {
    override func setUp() {
        super.setUp()
        // In an async test a stop-on-failure kills the runner, and xcodebuild stalls on the restart
        continueAfterFailure = true
    }

    // MARK: - Write Intents

    @MainActor
    func testLogWaterShowsInApp() async throws {
        try await run("LogWaterIntent", ["amount": Measurement(value: 500, unit: UnitVolume.milliliters)])

        let label = element(AccessibilityID.waterValueLabel)
        XCTAssertTrue(waitForLabel(of: label, toStartWith: "0.5"), "got \(label.label)")
    }

    @MainActor
    func testLogMoodSelectsItInApp() async throws {
        try await run("LogMoodIntent", ["mood": enumCase("MoodAppEnum", "sad")])

        let sad = app.buttons[AccessibilityID.moodButtonSad]
        scrollTo(sad)
        assertSelected(sad)
    }

    @MainActor
    func testAddMealShowsCardInApp() async throws {
        try await run("AddMealIntent", [
            "items": "Rice, beans",
            "size": enumCase("MealSizeAppEnum", "large"),
            "satisfaction": enumCase("MealSatisfactionAppEnum", "thirty")
        ])

        let card = assertExists(element(AccessibilityID.mealCard(0)))
        XCTAssertTrue(card.label.contains("Rice, beans"), "got \(card.label)")
        XCTAssertTrue(card.label.contains("Quantity: Large"), "got \(card.label)")
        XCTAssertTrue(card.label.contains("Satisfied: 30%"), "got \(card.label)")
    }

    @MainActor
    func testAddMealWithBlankItemsAsksAgainAndSavesNothing() async throws {
        do {
            try await run("AddMealIntent", ["items": " , "])
            XCTFail("Expected AddMealIntent to ask again for its items")
        } catch {
            // The test runner can't answer a re-ask, so it surfaces as an error naming the parameter
            XCTAssertTrue(error.localizedDescription.contains("'items'"), "got \(error)")
        }

        assertExists(element(AccessibilityID.mealsEmptyState))
    }

    @MainActor
    func testAddWorkoutShowsCardInApp() async throws {
        try await run("AddWorkoutIntent", [
            "name": "Swimming",
            "minutes": 45,
            "intensity": enumCase("WorkoutIntensityAppEnum", "high")
        ])

        let card = assertExists(element(AccessibilityID.workoutCard(0)))
        XCTAssertTrue(card.label.contains("Swimming"), "got \(card.label)")
        XCTAssertTrue(card.label.contains("Time: 45m"), "got \(card.label)")
        XCTAssertTrue(card.label.contains("Intensity: High"), "got \(card.label)")
    }

    // MARK: - Day Status

    func testDayStatusFollowsWhatWasLogged() async throws {
        let empty = try await dayStatus()
        XCTAssertEqual(empty, "Nothing logged today yet.")

        try await run("LogWaterIntent", ["amount": Measurement(value: 250, unit: UnitVolume.milliliters)])
        let oneCategory = try await dayStatus()
        XCTAssertEqual(oneCategory, "Log at least two categories to get today's status.")

        try await run("LogMoodIntent", ["mood": enumCase("MoodAppEnum", "sad")])
        let twoCategories = try await dayStatus()
        XCTAssertEqual(twoCategories, "Poor day: low water intake, no workout, sad mood.")
    }

    // MARK: - Stale Overwrite

    /// Regression: `MainView` used to keep its launch-time days and overwrite an intent's write on the next save.
    @MainActor
    func testIntentWriteWhileBackgroundedSurvivesAnInAppEdit() async throws {
        XCUIDevice.shared.press(.home)
        try await run("LogWaterIntent", ["amount": Measurement(value: 500, unit: UnitVolume.milliliters)])
        app.activate()

        let water = element(AccessibilityID.waterValueLabel)
        XCTAssertTrue(waitForLabel(of: water, toStartWith: "0.5"), "got \(water.label)")

        addMeal(items: ["Apple"])

        // Reloading from the store on the next activation shows what the meal save actually wrote
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(waitForLabel(of: water, toStartWith: "0.5"), "got \(water.label)")
        XCTAssertTrue(assertExists(element(AccessibilityID.mealCard(0))).label.contains("Apple"))
    }

    // MARK: - Frozen Contract

    /// Saved shortcuts replay every `AppEnum` case by raw value; each one must still resolve.
    func testEveryPersistedEnumRawValueResolves() async throws {
        for mood in ["good", "neutral", "sad"] {
            try await run("LogMoodIntent", ["mood": enumCase("MoodAppEnum", mood)])
        }
        for size in ["verySmall", "small", "medium", "large"] {
            try await run("AddMealIntent", ["items": "Toast", "size": enumCase("MealSizeAppEnum", size)])
        }
        for satisfaction in ["thirty", "fifty", "eighty", "hundred"] {
            try await run("AddMealIntent", [
                "items": "Toast",
                "satisfaction": enumCase("MealSatisfactionAppEnum", satisfaction)
            ])
        }
        for intensity in ["low", "medium", "high"] {
            try await run("AddWorkoutIntent", [
                "name": "Walk",
                "intensity": enumCase("WorkoutIntensityAppEnum", intensity)
            ])
        }
    }

    // MARK: - Helpers

    private var definitions: IntentDefinitions {
        IntentDefinitions(bundleIdentifier: "com.gustavoaraujo.health-tracker")
    }

    @discardableResult
    private func run(_ intent: String, _ parameters: KeyValuePairs<String, (any IntentValueExpressing)?> = [:])
        async throws -> ResolvedIntentResult
    {
        try await definitions.intents[intent].makeIntent.dynamicallyCall(withKeywordArguments: parameters).run()
    }

    private func enumCase(_ type: String, _ rawValue: String) -> AnyAppEnum {
        AnyAppEnum(typeIdentifier: type, rawValue: rawValue)
    }

    private func dayStatus() async throws -> String {
        try await run("GetDayStatusIntent").value.as(String.self)
    }

    /// Polls until the element's label starts with the prefix; intents update the UI via a notification.
    private func waitForLabel(of element: XCUIElement, toStartWith prefix: String) -> Bool {
        let predicate = NSPredicate(format: "label BEGINSWITH %@", prefix)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: 5) == .completed
    }
}
