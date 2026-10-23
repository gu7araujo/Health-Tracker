# Presentation Layer

The SwiftUI UI: an `@Observable` ViewModel that owns the screen's mutable state, stateless section views that render it, and reusable Liquid Glass components. The only layer that touches SwiftUI. It reaches the domain solely through use cases — never a repository or data source directly. Constructing a repository or data source here fails SwiftLint rule `presentation_no_data_layer`; the production convenience init (below) is the composition root and carries its `swiftlint:disable:next`.

## State & Data Flow

`MainViewModel` is the **single source of truth** for on-screen day data. State flows one way and mutations flow back through closures:

```
View → ViewModel → Use Case → Repository → DataSource
```

SwiftUI re-renders on `@Observable` changes; views never mutate day data themselves.

Periphery misreads an iOS 27 `@State` property used only through its `$binding` as unused (the `@State` macro hides the use): mark it `// periphery:ignore - used only via $binding (iOS 27 @State macro)`, as `MainView` does, and call the ignore out in the PR.

- `selectedDate` drives `currentDayData` (the matching day, or an empty one). Setting it calls `ensureDayDataExists`, which fabricates an empty `DayData` **in memory only** — `persistChanges` parses each day to `RecordedDayData`, so empty days are never written (mirrors the Domain parse-don't-validate rule).
- Every CRUD method delegates to `DayData`'s own ops, then `persistChanges`; saving also fire-and-forgets `CancelNotificationsUseCase`.

Two initializers keep the VM testable and convenient:

```swift
init(loadUseCase:saveUseCase:cancelNotificationsUseCase:logger:)   // explicit deps — unit tests
convenience init(repository: HealthDataRepositoryProtocol = HealthDataRepository(),
                 notificationService: NotificationServiceProtocol = NotificationService())  // production
```

## Localization

The app ships `en` and `pt-BR` (Brazil is the primary locale). Every user-facing string is localized; display text is never hardcoded. The two locales' `.strings` files stay in sync — a key added to one is added to both (enforced by `scripts/fitness/localization-parity.sh`):

- `HealthTracker/Resources/en.lproj/Localizable.strings`
- `HealthTracker/Resources/pt-BR.lproj/Localizable.strings`

Route user-facing text through `String(localized:)`; resolve locale- and timezone-sensitive APIs from the device:

```swift
Text(String(localized: "meals_section"))          // ✅ localized
formatter.locale   = Locale.current               // ✅ respects device settings
formatter.timeZone = TimeZone.current             // (never Locale(identifier: "pt_BR"))
```

This covers `DateFormatter`, `Calendar`, and any other locale/timezone-sensitive API (see `CalendarStrip`). Canonical references: `Mood.localizedName`, `Meal.Quantity.localizedName`. Fixed identifiers are enforced app-wide by SwiftLint rule `no_hardcoded_locale`.

Group keys by feature area with snake_case prefixes:

| Prefix | Usage |
|---|---|
| `meal_quantity_*` / `satisfaction_*` | `Meal.Quantity` / `Meal.Satisfaction` cases |
| `mood_*` | `Mood` cases |
| `day_status_explanation.*` / `day_status_reason.*` | `DayData.statusExplanation` strings |
| `*_section` / `empty_*` | Section headings / empty-state messages |
| `add_*` / `edit_*` | Modal titles and actions |

## Rules

Unidirectional flow — the ViewModel owns state, views render it and report intent through closures.

<rule_1>
**STATELESS SECTION VIEWS** — `MealsSectionView`, `WorkoutsSectionView`, `WaterSectionView`, and `MoodSectionView` take plain values in and closures out; they never hold the `MainViewModel`. Only `MainView` and `AddEditModal` reference the VM. New sections follow suit: data in, intent out.
</rule_1>

<rule_2>
**RULE OF THREE** — don't abstract on the first or second use. Duplicate until a pattern proves itself three times, then extract only when the commonality is structural, not accidental (how `CardView` earned its place).
</rule_2>

<rule_3>
**PRESENTATION TESTS** — cover the ViewModel and the user-facing flows.
- `MainViewModel`: each CRUD op (add/update/delete/move meal & workout, water, mood) against use-case fakes; `selectedDate` → `currentDayData`/`currentDayStatus`/`currentDayExplanation`; `ensureDayDataExists` creates but does not persist an empty day.
- UI flows: drive through `AccessibilityID` in `HealthTrackerUITests` — meal/workout add-edit-delete, water/mood, calendar navigation and empty states.
- Any new identifier lands in both `AccessibilityID.swift` and its UITests mirror.
</rule_3>
