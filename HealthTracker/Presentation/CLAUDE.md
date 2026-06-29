# UI Layer Architecture

## Directory Structure

| Path | File | Purpose |
|---|---|---|
| `ViewModels/` | `MainViewModel.swift` | Manages state and logic for the main health tracking screen |
| `Views/` | `MainView.swift` | Root view; owns `MainViewModel` via `@State` |
| `Views/` | `AddEditModal.swift` | Sheet for adding or editing a health entry |
| `Views/Components/` | `CardView.swift` | Reusable card with iOS 26 Liquid Glass `.glassEffect()` styling |
| `Views/Components/` | `CardListView.swift` | List wrapper styled with `CardView` |
| `Views/Components/` | `CalendarStrip.swift` | Horizontal date-picker strip for day navigation |

## Data Flow

1. `MainView` holds `@State private var viewModel = MainViewModel()`
2. User interactions trigger ViewModel methods
3. ViewModel updates internal state and calls appropriate use case
4. Use case coordinates with repository
5. Repository delegates to data source for persistence
6. SwiftUI observes ViewModel changes and re-renders

## Key Patterns

### State Management

- Uses Swift's native `@Observable` macro (not `ObservableObject`)
- View models coordinate between UI and use cases
- State flows unidirectionally: View → ViewModel → Use Case → Repository → DataSource

### Dependency Injection

```swift
// MainViewModel provides both explicit and convenience initializers
init(loadUseCase: LoadDayDataUseCase, saveUseCase: SaveDayDataUseCase) // Testable
convenience init(repository: HealthDataRepositoryProtocol = HealthDataRepository()) // Production
```

### Modifying Views

- Follow existing section-based composition pattern in `MainView`
- Extract complex sections into private structs (see `MealsSectionView`, `WorkoutsSectionView`)
- Use `CardView` for consistent glass effect styling
- Leverage iOS 26+ Liquid Glass with `.glassEffect()` modifier

## Rules

<rule_1>
```swift
// 1. DO NOT abstract on the first or second usage.
// 2. DUPLICATE code until the pattern is proven three times.
// 3. REFRACTOR only when the commonality is structural, not accidental.

// Initial usage: Keep it local
struct UserAvatar: View { ... }

// Second usage: Copy-paste if domains differ
struct EmployeeAvatar: View { ... }

// Third usage: Extract reusable component
struct CircleImage(url: URL): View { ... }
</rule_1>

## Language and Localization

The app supports multiple languages. Portuguese (Brazil) is the primary locale. All user-facing strings must go through the localization system — never hardcode display text.

### Localization Files

Both files must always be kept in sync when adding new keys:
- `HealthTracker/Resources/en.lproj/Localizable.strings` — English
- `HealthTracker/Resources/pt-BR.lproj/Localizable.strings` — Portuguese (Brazil)

### Adding Localized Strings

Always use `String(localized:)` for user-facing text in Swift code — never hardcode display strings:

```swift
// ✅ Correct
var localizedName: String {
    switch self {
    case .verySmall: String(localized: "meal_quantity_very_small")
    case .small:     String(localized: "meal_quantity_small")
    }
}

// ❌ Wrong — bypasses localization
var localizedName: String {
    switch self {
    case .verySmall: "Muito pequena"
    case .small:     "Pequena"
    }
}
```

Use the `Mood.localizedName` and `Meal.Quantity.localizedName` implementations as canonical references.

### Locale and Timezone Rules

**Never hardcode locale identifiers or timezones.** Always use the system values so the app respects the user's device settings:

```swift
// ✅ Correct
formatter.locale = Locale.current
formatter.timeZone = TimeZone.current
calendar.locale = Locale.current
calendar.timeZone = TimeZone.current

// ❌ Wrong — forces Portuguese regardless of device language
formatter.locale = Locale(identifier: "pt_BR")
formatter.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
```

This applies to `DateFormatter`, `Calendar`, and any other locale/timezone-sensitive APIs.

### Key Naming Conventions

Group keys by feature area using snake_case prefixes:

| Prefix | Usage |
|---|---|
| `meal_quantity_*` | `Meal.Quantity` enum cases |
| `satisfaction_*` | `Meal.Satisfaction` enum cases |
| `mood_*` | `Mood` enum cases |
| `day_status_explanation.*` | `DayData.statusExplanation` strings |
| `day_status_reason.*` | Status reason fragments |
| `empty_*` | Empty state messages |
| `add_*` / `edit_*` | Modal titles and actions |

### Anti-Patterns

<avoid>
❌ Hardcoding display strings in Swift source (e.g., `"Esta Semana"`, `"Grande"`)
❌ Using `Locale(identifier: "pt_BR")` anywhere in the codebase
❌ Using `TimeZone(identifier: "America/Sao_Paulo")` anywhere in the codebase
❌ Adding a key to only one `.strings` file — always update both
</avoid>
