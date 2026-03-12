# Domain Layer Architecture

## Directory Structure

| Path | Contents |
|------|----------|
| `Entities/` | Core data models: `DayData`, `Meal`, `Workout`, `Mood`, `DayStatus`, `RecordedDayData`, `HealthSection`, analytics entities |
| `Entities/DayData.swift` | Primary aggregate — holds meals, workouts, water, mood; computes `status` and `statusExplanation` |
| `Entities/Meal.swift` | `Meal` struct with nested `Quantity` (verySmall/small/medium/large) and `Satisfaction` enums |
| `Entities/Workout.swift` | `Workout` struct with nested `Duration` (1–300 min) |
| `Entities/Mood.swift` | `Mood` enum (good/neutral/sad) |
| `Entities/DayStatus.swift` | `DayStatus` enum (noData/incomplete/optimal/moderate/poor) |
| `Entities/RecordedDayData.swift` | Lightweight value type referencing a saved day |
| `Entities/AnalyticsData.swift` | Top-level analytics container |
| `Entities/AnalyticsPeriod.swift` | Enum for analytics time windows (week/month/year) |
| `Entities/OverallAnalytics.swift` | Aggregated analytics across all categories |
| `Entities/MealAnalytics.swift` | Meal-specific analytics |
| `Entities/WorkoutAnalytics.swift` | Workout-specific analytics with `DurationRange` enum |
| `Entities/WaterAnalytics.swift` | Water-specific analytics |
| `Entities/MoodAnalytics.swift` | Mood-specific analytics |
| `Protocols/` | Abstractions for infrastructure dependencies |
| `Protocols/HealthDataRepositoryProtocol.swift` | Persistence contract for loading/saving `DayData` |
| `Protocols/NotificationServiceProtocol.swift` | Notification scheduling contract; includes `NotificationAuthorizationStatus`, `NotificationAuthorizationOptions`, and `NotificationCenterDelegate` |
| `Protocols/LoggerProtocol.swift` | Logging abstraction |
| `UseCases/` | Single-responsibility business operations |
| `UseCases/LoadDayDataUseCase.swift` | Fetch day records from the repository |
| `UseCases/SaveDayDataUseCase.swift` | Persist a `DayData` entry |
| `UseCases/CalculateAnalyticsUseCase.swift` | Compute analytics from stored records |
| `UseCases/ScheduleNotificationsUseCase.swift` | Schedule health-reminder notifications |
| `UseCases/CancelNotificationsUseCase.swift` | Cancel previously scheduled notifications |
| `UseCases/RequestNotificationPermissionUseCase.swift` | Request system notification authorization |

## Rules

<rule_1>
**WITNESS PATTERN FOR ACCESS CONTROL**: Turn conventions into compile-time requirements
- A **Witness** is a value that proves a precondition is met (e.g., feature enabled, user authenticated, data saved)
- Replace boolean flags with optional witness types (e.g., `isEnabled: Bool` → `enabled: FeatureEnabled?`)
- Use `fileprivate init()` to prevent forging witnesses outside their origin
- Require witnesses as non-optional arguments to enforce access control at compile time
- Code fails to compile if access control isn't enforced, catching mistakes early
- Use "black hole" arguments (`init(_: Witness)`) when witness is only proof, not data
</rule_1>

### Entity Modifications
- Entities are `Codable`, so changes may require migration logic
- `DayData` computes health status based on business rules (see `status`, `meetsOptimalCriteria`, `meetsModerateCriteria`, `meetsPoorCriteria`)
  - **Status thresholds**: 0 categories → `.noData`, 1 category → `.incomplete`, 2+ categories → evaluated for `.optimal`/`.moderate`/`.poor`
  - **Health Status Logic** (comprehensive evaluation of all 4 categories):
    - 🟢 **Optimal** (ALL must be true): Only verySmall/small meals OR ≤1 medium meal + Water ≥1.8L + Workouts ≥30 min total + Mood = good
    - 🟡 **Moderate** (ANY one of): Exactly 1 medium meal (when other criteria prevent optimal) OR Water 1.0-1.7L OR Workouts <30 min OR Mood = neutral
    - 🔴 **Poor** (ANY one of): 2+ medium meals OR any large meal OR Water <1.0L (or nil) OR Mood = sad (workouts don't affect poor status)
    - ⚪ **Incomplete**: Only 1 category filled
    - **Note**: Meal satiety is **completely ignored** - only meal size (verySmall/small/medium/large) affects status
    - **Workout duration**: `Workout.Duration` is a struct storing minutes as Int (1-300 range). Sums all workouts in a day (e.g., 2x 15min = 30min total). Supports free-form time input via DatePicker in AddEditModal with `Duration(minutes:)` constructor.
- Nested enums have localized names (e.g., `Meal.Quantity.localizedName`)

## Available Skills

Use the following skills when writing or reviewing domain layer code. See the **Available Skills** section in the root `AGENTS.md` for the full skill list and descriptions.

| Skill | When to use |
|-------|-------------|
| `swift-concurrency` | Designing async use case interfaces, handling actor isolation on domain protocols, or working with `async`/`await` in business logic |
| `swift-api-design-guidelines` | Naming entities, protocols, use cases, or enum cases to align with Swift API conventions |

Invoke skills via the `Skill` tool **before** responding to any task they cover.
