# Domain Layer

The business core: strongly-typed entities, the abstractions the outer layers depend on, and single-responsibility use cases. Owns the health-status rules. No SwiftUI or persistence framework leaks in here — except the small UI affordances (`localizedName`, `color`) some entities expose for the Presentation layer.

## Health Status

`DayData.status` is the app's core rule. This section is its single source of truth. Only **meal size** counts — `Satisfaction` is ignored everywhere. Workout minutes are summed across the day (`Duration.minutes`, 1–300).

Count the filled categories among `{meals, water, workouts, mood}`:

- **0 → `.noData`**
- **1 → `.incomplete`**
- **2–4 →** evaluated in this order (first match wins):

1. 🔴 **`.poor`** — checked first, any poor signal wins. ANY of: ≥3 medium meals or any large meal; water < 1.0L (nil counts as 0); mood = sad. *Workouts never trigger poor.*
2. 🟢 **`.optimal`** — ALL of: meals present and only verySmall/small with ≤1 medium (no large); water ≥ 1.8L; total workout ≥ 30 min; mood = good.
3. 🟡 **`.moderate`** — ANY of: exactly 2 medium meals; water 1.0–<1.8L; total workout < 30 min; mood = neutral.
4. 🔴 **`.poor`** — fallback when data exists but matches none of the above.

`statusExplanation` returns a localized reason string for moderate/poor (and a success line for optimal); it is `nil` for `.noData`/`.incomplete`.

## Rules

Type-Driven Design — encode invariants in types so they hold by construction (mirrors `Data/CLAUDE.md`, from the other side of the boundary).

<rule_1>
**PARSE, DON'T VALIDATE** — `RecordedDayData`'s failable init is the only way to make one, so an empty day is unrepresentable downstream. Repository and use cases traffic in `RecordedDayData`, never raw `DayData`, so the guarantee can't be bypassed.
</rule_1>

<rule_2>
**TOLERANT DECODE AT THE ENTITY** — `Meal` and `Workout` carry custom `Codable` inits that upgrade legacy shapes in place: `Meal` reads a legacy single `description` when `items` is absent; `Workout.Intensity` defaults to `.medium` when missing; `Workout.Duration` maps the old enum raw values (0–6) to real minutes. This is per-field, decode-time healing — distinct from the one-time file migration in `Data/Migration/`. Any change to a persisted entity's shape lands here first; see the root **Data Migrations** policy before touching it.
</rule_2>

<rule_3>
**DOMAIN OWNS NO FRAMEWORKS** — depend on the `Protocols/` abstractions, not concrete services. Keep framework types (UserNotifications, persistence) behind those protocols; where the domain needs a platform concept, model a plain domain mirror (as the notification types do) rather than importing the framework.
</rule_3>

<rule_4>
**DOMAIN TESTS** — every entity computation and use case earns a focused unit test.
- `DayData`: each status tier and its boundaries (the thresholds above), plus the CRUD/move ops.
- Entities: round-trip `Codable` including each legacy-decode path in rule 2.
- Use cases: drive them against protocol fakes (never real services), asserting the delegated calls; `await` async use cases directly — no `XCTestExpectation`.
</rule_4>
