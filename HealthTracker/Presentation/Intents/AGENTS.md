# App Intents

The Siri/Shortcuts/Spotlight entry points (`LogWaterIntent`, `LogMoodIntent`, `AddMealIntent`, `AddWorkoutIntent`, `GetDayStatusIntent`) and `HealthTrackerShortcuts`. Like views, they reach the domain only through use cases. `Presentation/AGENTS.md` applies here too; this file adds what only intents need.

## Rules

<rule_1>
**FROZEN CONTRACT** — intent type names, `AppEnum` raw values (explicit strings in `IntentEnums.swift`, guarded by tests) and App Shortcut phrases are persisted by Shortcuts and Siri. Add to them; keep every existing name and value as it is. `AppEnum`s mirror domain enums so Domain stays framework-free.
</rule_1>

<rule_2>
**ONE WRITE, LAST** — resolve every parameter, including any `needsValueError` re-ask, before the single save. `perform()` can restart from the top, so anything saved earlier would be saved twice.
</rule_2>

<rule_3>
**EVERY WRITE POSTS `healthDataDidChange`** — writes and undos go through `UpdateDayDataUseCase.executeAndNotify`. `MainView` reloads on that notification and on scene activation, so its in-memory days can't overwrite an intent's write.
</rule_3>

<rule_4>
**THIN `perform()`, TESTABLE CORE** — `perform()` builds live use cases from `IntentUseCaseFactory`, then calls `run(with:on:)`, `registerUndo(on:useCase:change:)` and `cancelTodaysNotifications()`. Unit tests drive `run`/`registerUndo` with `MockHealthDataRepository` and a real `UndoManager` (`UndoManager.registerAndUndo`); `perform()` itself is covered end to end by `HealthTrackerIntentsUITests`, which `scripts/quality --full` counts toward the per-file floor. Build dependencies through the factory rather than `@Dependency`: an unregistered one is a `fatalError` on a cold Siri launch.
</rule_4>

<rule_5>
**RUN-TIME TEXT IS RESOLVED IN THE APP** — Siri and Shortcuts look a key up in their own process and language, which can differ from the app's (on the iOS 27 simulator the Shortcuts runner reads no preferences and shows English). So every dialog, prompt (`requestValueDialog`, `requestDisambiguationDialog`, `needsValueError`) and error message goes through `LocalizedStringResource.resolvedInApp`, built by a static on the intent (`LogMoodIntent.dialog(for:)`, `AddMealIntent.itemsPrompt`) and tested with `readByForeignHost`. Static metadata (titles, parameter names, summaries) is read by the system from the build and stays keyed.
</rule_5>

## Conventions

- **Isolation.** Leave intent and `AppEnum` types unannotated: they already infer nonisolated because the protocols refine `Sendable`, and an explicit `nonisolated struct` breaks the build on its `@Parameter` vars. Mark `perform()`, `run(with:on:)` and `registerUndo(on:…)` `@MainActor`, where the use cases and `undoManager` live.
- **Strings.** Titles, parameters and dialogs use literal `intent_*` keys in `Localizable.strings`. Summaries are keyed with `${param}` (`"intent_log_water_summary ${amount}"`), interpolated dialogs with `%@`. Phrases are keyed by their English source in `AppShortcuts.strings` (en and pt-BR), and every phrase needs `\(.applicationName)`.
- **Spotlight.** A search of the app's name shows about three shortcuts, starting from `HealthTrackerShortcuts`' order, so the most common logs go first. Keep `AppEnum`s out of phrases: each case becomes its own result and crowds the others out.
