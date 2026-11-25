//
//  AppIntentsUITests.swift
//  HealthTrackerIntentsUITests
//

import AppIntentsTesting
import XCTest

/// Runs the App Intents the way Siri and Shortcuts do: out of process, through `AppIntentsTesting`,
/// inside the app `setUpWithError` launched with `-uiTesting`, so they share its isolated store.
/// Intents, enums, and raw values are addressed by their persisted names, so a rename fails here first.
final class AppIntentsUITests: HealthTrackerUITestCase {
    /// Whether this run has warmed up its intents, or tried to: see `warmUpIntents()`.
    private static var warmUpAttempted = false

    /// Runs before the base class's `setUpWithError`, which then relaunches the app onto a fresh store:
    /// a warm-up write that timed out may still have saved.
    override func setUp() async throws {
        try await super.setUp()
        // Once per run: a warm-up that failed would fail the same way for every test
        guard !Self.warmUpAttempted else { return }
        Self.warmUpAttempted = true
        launchApp()
        try await warmUpIntents()
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        // In an async test a stop-on-failure kills the runner, and xcodebuild stalls on the restart.
        // Set here, after super: the base class's setUpWithError resets it to false
        continueAfterFailure = true
    }

    // MARK: - Write Intents

    @MainActor
    func testLogWaterShowsInApp() async throws {
        try await run("LogWaterIntent", ["amount": 500])

        let label = element(AccessibilityID.waterValueLabel)
        assertLabel(of: label, startsWith: "0.5")
    }

    @MainActor
    func testLogWaterWithoutAmountAsksForItAndSavesNothing() async throws {
        do {
            try await run("LogWaterIntent")
            XCTFail("Expected LogWaterIntent to ask for its amount")
        } catch {
            // The test runner can't answer the question, so it surfaces as an error naming the parameter
            XCTAssertTrue(error.localizedDescription.contains("'amount'"), "got \(error)")
        }

        let label = assertExists(element(AccessibilityID.waterValueLabel)).label
        XCTAssertTrue(label.hasPrefix("0.0"), "got \(label)")
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
        XCTAssertTrue(card.label.contains("Size: Large"), "got \(card.label)")
        XCTAssertTrue(card.label.contains("Satisfaction: 30%"), "got \(card.label)")
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
        XCTAssertTrue(card.label.contains("Duration: 45m"), "got \(card.label)")
        XCTAssertTrue(card.label.contains("Intensity: High"), "got \(card.label)")
    }

    // MARK: - Day Status

    func testDayStatusFollowsWhatWasLogged() async throws {
        let empty = try await dayStatus()
        XCTAssertEqual(empty, "Nothing logged today yet.")

        try await run("LogWaterIntent", ["amount": 250])
        let oneCategory = try await dayStatus()
        XCTAssertEqual(oneCategory, "Log at least two categories to get today's status.")

        try await run("LogMoodIntent", ["mood": enumCase("MoodAppEnum", "sad")])
        let twoCategories = try await dayStatus()
        XCTAssertEqual(twoCategories, "Below targets: low water intake, no workout, bad mood.")
    }

    // MARK: - Stale Overwrite

    /// Regression: `MainView` used to keep its launch-time days and overwrite an intent's write on the next save.
    @MainActor
    func testIntentWriteWhileBackgroundedSurvivesAnInAppEdit() async throws {
        XCUIDevice.shared.press(.home)
        try await run("LogWaterIntent", ["amount": 500])
        app.activate()

        let water = element(AccessibilityID.waterValueLabel)
        assertLabel(of: water, startsWith: "0.5")

        addMeal(items: ["Apple"])

        // Reloading from the store on the next activation shows what the meal save actually wrote
        XCUIDevice.shared.press(.home)
        app.activate()
        assertLabel(of: water, startsWith: "0.5")
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

    /// On a freshly installed or erased simulator the system isn't ready for this app's intents: the first
    /// calls fail with "… is not present" until it registers the app's metadata, then the first writes time out
    /// at 30 s (`LNConnectionErrorDomain` 1014) for up to about a minute (#86). Retries one write on those two
    /// errors until it succeeds. Any other error is a real failure and is thrown at once.
    private func warmUpIntents() async throws {
        let deadline = Duration.seconds(100)
        let start = ContinuousClock.now
        while true {
            do {
                try await run("LogWaterIntent", ["amount": 500])
                break
            } catch {
                let notReady = [("AppIntentsServicesMetadataErrorDomain", 400), ("LNConnectionErrorDomain", 1014)]
                    .contains { $0 == ((error as NSError).domain, (error as NSError).code) }
                guard notReady else { throw error }
                guard ContinuousClock.now - start < deadline else {
                    throw IntentsNotReady(description: "App Intents service not ready after \(deadline): \(error)")
                }
                // A back-off between failed calls, not a UI wait: "not present" fails in milliseconds
                try await Task.sleep(for: .seconds(1))
            }
        }
    }

    private struct IntentsNotReady: Error, CustomStringConvertible {
        let description: String
    }

    private func enumCase(_ type: String, _ rawValue: String) -> AnyAppEnum {
        AnyAppEnum(typeIdentifier: type, rawValue: rawValue)
    }

    private func dayStatus() async throws -> String {
        try await run("GetDayStatusIntent").value.as(String.self)
    }

    /// Polls until the element's label starts with the prefix; intents update the UI via a notification.
    /// Reads through `waitUntil` and `snapshot()`, since a predicate expectation gives up on one slow
    /// query and reported a label that already matched (#117).
    private func assertLabel(of element: XCUIElement, startsWith prefix: String,
                             file: StaticString = #filePath, line: UInt = #line)
    {
        var text = ""
        if waitUntil({
            do {
                text = try element.snapshot().label
            } catch {
                text = "<no snapshot: \(error.localizedDescription)>"
            }
            return text.hasPrefix(prefix)
        }) { return }
        XCTFail("Expected a label starting with \(prefix), got: \(text)", file: file, line: line)
    }
}
