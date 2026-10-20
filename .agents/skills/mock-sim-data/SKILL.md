---
name: mock-sim-data
description: Seed the running iOS Simulator with mock HealthTracker data by editing its HealthTrackerData.json store directly, then relaunching so the app reloads. Use when the user wants to mock, seed, or prefill app data to simulate a scenario (e.g. App Store screenshots or validate some feature) rather than entering it by tapping through screens.
---

Seed the app by editing its on-disk JSON store, not by tapping through screens.

The store is **cold**: the app reads it only at launch and write-through on every in-app edit. So edit while the app is terminated, then relaunch. A live app clobbers your file the moment the user touches anything.

## Steps

### 1. Locate the booted simulator and its data file
- Booted device: `xcrun simctl list devices | grep Booted` → the UDID. Parallel agents can boot several; pick the one named by your project's run destination (`XcodeListRunDestinations` → `activeDestinationDisplayTitle`).
- The file (app uses the local Documents fallback, **not** iCloud — search, don't assume the path):
  `find ~/Library/Developer/CoreSimulator/Devices/<UDID>/data -name "HealthTrackerData.json" 2>/dev/null`

The UDID and the `Containers/Data/Application/<GUID>/` segment differ per machine and change on reinstall — always resolve them fresh, never hardcode.

**Done when:** you hold the absolute path to the live `HealthTrackerData.json`.

### 2. Terminate the app
`xcrun simctl terminate <UDID> com.gustavoaraujo.health-tracker`

This drops the app's in-memory `days` (so it can't overwrite your edit) and forces a clean reload on next launch.

**Done when:** the app is not running.

### 3. Back up
Copy the live file to `HealthTrackerData.premock-backup.json` beside it. Leave the app's own `HealthTrackerData.backup.json` alone — it's a separate rolling backup.

**Done when:** the `.premock-backup.json` copy exists.

### 4. Build and write the JSON
Construct the payload against the [schema](#schema). When the scenario targets specific calendar ring colors or the status line, derive them from the [status logic](#status-and-ring-reference) and self-verify each day (replicate `DayData.status` in your generator and print the expected status per day). Write valid JSON to the target path.

**Done when:** the file is written and every day's expected status, ring color, and status line are confirmed against the scenario.

### 5. Launch and confirm
`xcrun simctl launch <UDID> com.gustavoaraujo.health-tracker`

**Done when:** the app is up and showing the seeded data (confirm with a RocketSim/simulator screenshot when the scenario's appearance matters).

## Schema

Top level `{ "days": [ <day>, ... ] }`. One `<day>`:

```jsonc
{
  "date": 806425200.0,        // CFAbsoluteTime: seconds since 2001-01-01 00:00 UTC
  "meals": [ { "id": "<UUID>", "items": ["..."], "quantity": 0-3, "satisfaction": 0-3 } ],
  "water": 2.6,               // liters (Double); omit the key for "no water"
  "workouts": [ { "id": "<UUID>", "description": "...", "duration": { "minutes": 1-300 }, "intensity": 0-2 } ],
  "mood": "Good"              // "Good" | "Neutral" | "Sad"; omit for none
}
```

Enum raw values (source of truth: `HealthTracker/Domain/Entities/{Meal,Workout,Mood}.swift`):
- `quantity`: 0 verySmall · 1 small · 2 medium · 3 large
- `satisfaction`: 0 = 30% · 1 = 50% · 2 = 80% · 3 = 100%
- `intensity`: 0 low · 1 medium · 2 high

`date` decodes via Swift's default `.deferredToDate`. Store each day at **local noon** (on the UTC-3 host, 15:00 UTC — e.g. `2026-07-22` → `806425200.0`) so it lands on the intended calendar day regardless of timezone; days are matched by `Calendar.current.isDate(_:inSameDayAs:)`. A day with zero categories is dropped on load (`RecordedDayData.init?`), so give every day ≥1 category.

## Status and ring reference

Consult this only when the scenario cares about the calendar ring color or the status line.

- **Ring color** = `DayData.status.color`: optimal → green, moderate → yellow, poor → red, incomplete → outline, noData → none. The thresholds (`meetsOptimalCriteria` / `meetsModerateCriteria` / `meetsPoorCriteria`) live in `HealthTracker/Domain/Entities/DayData.swift` — read them to hit a specific color.
- **Poor is evaluated first:** water < 1.0 L (or missing), any large meal, 3+ medium meals, or Sad mood forces red — even when other signals read moderate. To keep a day moderate, keep water ≥ 1.0 L, ≤ 2 medium meals, no large meal, mood ≠ Sad.
- **The status line under the strip renders only for moderate and poor days** — `MainView` hides it for optimal, incomplete, and noData. Its wording comes from `DayData.statusExplanation` + the `day_status_*` keys in `HealthTracker/Resources/en.lproj/Localizable.strings`. Read those to predict the exact sentence.

## Calendar layout

The strip pages by week, Monday-first, and opens on the current week (`selectedDate` defaults to today). Future days render grey with no ring. So the default page shows rings only for this week's past-and-today days — to display several ring colors without scrolling, put varied statuses on the earlier days of the current week; for a full week of rings, populate a past week (the user scrolls left).

## Restore

Copy `HealthTrackerData.premock-backup.json` back over `HealthTrackerData.json` and relaunch (steps 2 → 5).
