# Day Status Explanation Section Design

**Date:** 2026-03-08
**Status:** Approved

## Context

The HealthTracker app displays day status indicators (green, yellow, red circles) in the calendar strip, but users don't understand why a particular day received its color classification. This feature adds an explanation section at the bottom of the main screen that clearly states what went right or wrong for the selected day.

## Requirements

- Display explanation at the bottom of the scrollable list (MainView)
- Gray background section without a title
- Direct and concise tone
- Show what went right/wrong for the day
- Only visible for days with complete data (green/yellow/red status)
- Hidden for days with no data or incomplete data (gray status)
- Fully localized in Portuguese (Brazil) and English
- Avoid code duplication - reuse existing status calculation logic

## Design Overview

### Architecture Approach

Extend the domain layer to generate explanations alongside status calculation, maintaining clean separation of concerns and avoiding logic duplication.

**Files to modify:**
1. `HealthTracker/Domain/Entities/DayData.swift` - Add explanation generation
2. `HealthTracker/Domain/Entities/DayStatus.swift` - Add explanation support (if needed)
3. `HealthTracker/Presentation/ViewModels/MainViewModel.swift` - Expose explanation to view
4. `HealthTracker/Presentation/Views/MainView.swift` - Add gray explanation section
5. `HealthTracker/Resources/Localizations/pt-BR.lproj/Localizable.strings` - Add PT-BR strings
6. `HealthTracker/Resources/Localizations/en.lproj/Localizable.strings` - Add EN strings

### Data Flow

```
DayData.statusExplanation
  ↓
Evaluates criteria once (meals, water, workouts, mood)
  ↓
Collects reasons during evaluation (no duplication)
  ↓
Returns localized explanation string
  ↓
MainViewModel exposes to view
  ↓
MainView displays in gray section (if status allows)
```

## Implementation Details

### Domain Layer (DayData.swift)

Add a new computed property `statusExplanation` that:
- Reuses existing helper properties (`totalWorkoutDuration`, meal filters, etc.)
- Evaluates criteria once and collects reasons
- Returns localized explanation string
- Leverages the same logic as `meetsOptimalCriteria`, `meetsModerateCriteria`, `meetsPoorCriteria`

**Strategy to avoid duplication:**
Instead of duplicating the status checks, extract the individual criteria checks (meals, water, workouts, mood) and reuse them in both status calculation and explanation generation.

### Explanation Text Format

**Optimal (Green):**
- English: "Good day: All targets met"
- Portuguese: "Ótimo dia: Todas as metas atingidas"

**Moderate (Yellow):**
- Format: "Moderate day: [reason1], [reason2]"
- English examples:
  - "Moderate day: 1 medium meal"
  - "Moderate day: moderate water intake (1.5L)"
  - "Moderate day: insufficient workout (<30min), neutral mood"
- Portuguese: "Dia moderado: [razão1], [razão2]"

**Poor (Red):**
- Format: "Poor day: [reason1], [reason2]"
- English examples:
  - "Poor day: multiple large/medium meals"
  - "Poor day: low water intake (0.5L), sad mood"
- Portuguese: "Dia ruim: [razão1], [razão2]"

**No Data / Incomplete:**
- No explanation section displayed

### Localization Keys

```
// Status headers
day_status_explanation.optimal
day_status_explanation.moderate
day_status_explanation.poor

// Reason strings
day_status_reason.meals_one_medium
day_status_reason.meals_multiple_medium
day_status_reason.water_low (with %.1fL format)
day_status_reason.water_moderate (with %.1fL format)
day_status_reason.water_none
day_status_reason.workout_insufficient
day_status_reason.workout_none
day_status_reason.mood_neutral
day_status_reason.mood_sad
```

### UI Component (MainView.swift)

Add at the bottom of the List, after the Mood section:

```swift
if let explanation = viewModel.currentDayExplanation,
   viewModel.currentDayStatus != .noData && viewModel.currentDayStatus != .incomplete {
    Section {
        Text(explanation)
            .font(.subheadline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }
    .listRowBackground(Color.secondary.opacity(0.2))
    .listRowInsets(EdgeInsets())
}
```

**Visual characteristics:**
- Gray background using `.secondary` color with opacity
- No section title
- Left-aligned text
- Consistent padding with other sections
- Scrollable with the rest of the list

### ViewModel Exposure (MainViewModel.swift)

Add computed properties:
```swift
var currentDayExplanation: String? {
    currentDay?.statusExplanation
}

var currentDayStatus: DayStatus {
    currentDay?.status ?? .noData
}
```

## Verification & Testing

### Manual Testing Scenarios

1. **Optimal day (Green)**:
   - Add: 2 small meals, 2.0L water, 30+ min workout, good mood
   - Expected: "Good day: All targets met" / "Ótimo dia: Todas as metas atingidas"

2. **Moderate day (Yellow) - Single issue**:
   - Add: 1 medium meal, 2.0L water, 30min workout, good mood
   - Expected: "Moderate day: 1 medium meal" / "Dia moderado: 1 refeição média"

3. **Moderate day (Yellow) - Multiple issues**:
   - Add: Small meals, 1.5L water, 20min workout, neutral mood
   - Expected: Shows multiple reasons combined

4. **Poor day (Red) - Single issue**:
   - Add: Small meals, 0.5L water, 30min workout, good mood
   - Expected: "Poor day: low water intake (0.5L)" / "Dia ruim: baixa ingestão de água (0.5L)"

5. **Poor day (Red) - Multiple issues**:
   - Add: 2 medium meals, 0.3L water, no workout, sad mood
   - Expected: Shows multiple reasons combined

6. **No data**:
   - Don't add any data
   - Expected: No gray explanation section appears

7. **Incomplete data**:
   - Add only 1 category (e.g., just water)
   - Expected: No gray explanation section appears

### Localization Testing

- Switch device to English → Verify English strings
- Switch device to Portuguese (Brazil) → Verify Portuguese strings
- Verify all format strings display correctly (e.g., water amounts)

### Code Quality Checks

- Run SwiftLint → No new warnings
- Run SwiftFormat → Code properly formatted
- Build succeeds with no errors or warnings
- No logic duplication between status calculation and explanation generation

## Success Criteria

- ✅ Explanation section appears at bottom of main screen
- ✅ Gray background without title
- ✅ Direct, concise explanations
- ✅ Shows what went right (green) or wrong (yellow/red)
- ✅ Hidden for no data and incomplete days
- ✅ Fully localized in PT-BR and English
- ✅ No code duplication in status logic
- ✅ Maintains clean architecture (domain/presentation separation)
