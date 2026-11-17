# App Intents UI Test Suite

`AppIntentsUITests.swift` runs the intents the way Siri does, through `AppIntentsTesting`. It is its own target because it **deploys to iOS 27**: any file importing that framework stops a whole test bundle from loading on iOS 26. `HealthTrackerUITests/AGENTS.md` applies here too (same base class, same rules); this file adds what only this suite needs.

`scripts/quality --full` runs the suite and counts it in app coverage and the per-file floor. Which simulator it needs, and running it alone: `quality-gate` and `cli-test` skills.

- **Shares `HealthTrackerUITests/Support/`.** The three files are members of both targets, so a new `Support` file needs both checkboxes.
- **Isolated store.** `setUp` launches the app with `-uiTesting` first. The intents then run inside that process, and `IntentUseCaseFactory` builds them from `UITestingSupport.makeRepository()`, which keeps one temp directory per launch. Without a launched app, the system would cold-launch it and the intents would hit the real store.
- **Warm-up once per run.** On a fresh or erased simulator the first intent calls fail (`… is not present`, then 30 s `LNConnectionErrorDomain` 1014 timeouts on writes) for up to about a minute, so the first test's `setUp` retries one `LogWaterIntent` on those two errors until it succeeds, then relaunches onto a fresh store (#86). That first test takes up to ~2.5 min. Its 1 s back-off between failed calls is the one exception to rule 3's no-sleep (a failing service call, not a UI wait); keep tests' own intent calls free of retries and delays.
- **Persisted names are the API.** Intents, `AppEnum`s and raw values are addressed as strings (`"LogWaterIntent"`, `"MoodAppEnum"`, `"sad"`), so a rename of the frozen contract (`HealthTracker/Presentation/Intents/AGENTS.md`) fails here.
- **`continueAfterFailure = true`.** In an `async` XCTest, stopping on failure kills the runner, and xcodebuild then stalls on the restart.
- **Assert through the app's UI and `GetDayStatusIntent`'s returned value.** The runner can't read spoken dialogs or answer a re-ask: a `needsValueError` surfaces as an error naming the parameter.
