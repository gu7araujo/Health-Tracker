# Codebase Concerns

**Analysis Date:** 2026-02-26

## Tech Debt

**Force-unwrapped Date Calculations in Chart Previews:**
- Issue: Using force-unwrap (`!`) on optional dates in SwiftUI preview code
- Files:
  - `HealthTracker/Presentation/Views/Components/Charts/WorkoutsBarChart.swift` (lines 54-57)
  - `HealthTracker/Presentation/Views/Components/Charts/WaterLineChart.swift` (lines 74-80, 83)
- Impact: Will crash if Calendar date calculations fail (extremely rare but not impossible in edge cases like invalid time zones)
- Fix approach: Replace force-unwraps with nil-coalescing to fallback dates, or use `guard let` with early return in preview code

**Legacy Data Format Migration Code Still Present:**
- Issue: Migration code from enum-based workout duration to minute-based duration is complete but legacy handling code remains
- Files:
  - `HealthTracker/Domain/Entities/Workout.swift` (lines 60-73) - Legacy decoding path
  - `HealthTracker/Data/Migration/DataMigration.swift` (entire file, 144 lines)
- Impact: Increases code complexity and maintenance burden; migration flags stored in UserDefaults will persist forever
- Fix approach: After sufficient time in production (6-12 months), remove legacy decoding path and migration utilities. Consider versioning the data format instead.

**Timezone Fallback Pattern:**
- Issue: Multiple locations fallback to `.current` timezone if "America/Sao_Paulo" identifier fails
- Files:
  - `HealthTracker/Presentation/Views/Components/CalendarStrip.swift` (lines 24, 86)
- Impact: Inconsistent behavior if timezone identifier becomes invalid; app will work but dates may be wrong for Brazilian users
- Fix approach: Consider failing loudly in debug builds or logging warnings. Add unit tests to verify timezone handling.

**No Error Recovery for iCloud Drive Unavailability:**
- Issue: App falls back to local Documents directory silently when iCloud is unavailable
- Files:
  - `HealthTracker/Data/DataSources/ICloudDriveDataSource.swift` (lines 23-32)
- Impact: Users won't know their data isn't syncing; data could become split between devices
- Fix approach: Add user-facing notification when iCloud is unavailable. Consider periodic sync checks and retry logic.

## Known Bugs

**No validation on empty descriptions:**
- Symptoms: Users can save meals/workouts with empty description strings
- Files: `HealthTracker/Presentation/Views/AddEditModal.swift` (lines 104-107)
- Trigger: Open add/edit modal, leave text field empty, tap "Salvar"
- Workaround: None - empty entries are saved successfully

**CalendarStrip Infinite Loading:**
- Symptoms: `needsMorePastDates` flag can trigger rapid successive loads
- Files: `HealthTracker/Presentation/Views/Components/CalendarStrip.swift` (lines 141-146)
- Trigger: Rapidly scroll backward through calendar
- Workaround: 0.1 second delay prevents most issues but edge case remains

## Security Considerations

**UserDefaults Storage Still Referenced:**
- Risk: Old data may still exist in UserDefaults after iCloud migration
- Files: `HealthTracker/Data/Migration/DataMigration.swift` (line 47)
- Current mitigation: Migration code removes "store" key after successful migration
- Recommendations: Add periodic cleanup check; consider encrypting sensitive data even in iCloud Documents

**File Coordination Error Handling:**
- Risk: File coordination errors are logged but not handled
- Files: `HealthTracker/Data/DataSources/ICloudDriveDataSource.swift` (lines 59-62, 97-100)
- Current mitigation: Silent failure returns empty array on read; data loss on write
- Recommendations: Implement retry logic with exponential backoff; notify user of persistent failures

**No Input Sanitization:**
- Risk: User text input is not sanitized before encoding/storage
- Files: `HealthTracker/Presentation/Views/AddEditModal.swift` (lines 79-82)
- Current mitigation: None - relies on Swift string handling
- Recommendations: Add length limits (e.g., 200 characters for descriptions); strip control characters

## Performance Bottlenecks

**CalculateAnalyticsUseCase Complexity:**
- Problem: Single 384-line file with multiple O(n²) nested loops
- Files: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift`
- Cause: Multiple passes over same data set; no caching of intermediate calculations
- Improvement path:
  - Split into smaller, focused calculators (MealAnalyticsCalculator, WorkoutAnalyticsCalculator, etc.)
  - Cache intermediate results when period hasn't changed
  - Consider lazy calculation for analytics not visible on screen

**MainView Rebuild on Any State Change:**
- Problem: 392-line view file with computed properties that recalculate on every state update
- Files: `HealthTracker/Presentation/Views/MainView.swift`
- Cause: SwiftUI body recalculation; no view granularity
- Improvement path: Split into smaller child views with isolated state; use `@Observable` more strategically

**CalendarStrip Date Array Growth:**
- Problem: Dates array grows unbounded as user scrolls backward
- Files: `HealthTracker/Presentation/Views/Components/CalendarStrip.swift` (lines 164)
- Cause: New dates prepended but old dates never removed
- Improvement path: Implement sliding window (keep only last 90 days in memory); use lazy loading

**Synchronous File I/O on Main Thread:**
- Problem: File read/write operations happen synchronously during save and load
- Files: `HealthTracker/Data/DataSources/ICloudDriveDataSource.swift` (lines 43-56, 75-95)
- Cause: Explicitly designed for main actor; justified by small payload assumption
- Improvement path: Move to background thread with Task/await; update UI on main thread after completion

## Fragile Areas

**DayData Status Calculation Logic:**
- Files: `HealthTracker/Domain/Entities/DayData.swift` (lines 70-163)
- Why fragile: Complex nested conditionals with multiple criteria; easy to introduce logic errors
- Safe modification: Always add corresponding unit tests; 166 tests exist but verify coverage of new criteria
- Test coverage: Good - `HealthTrackerTests/Domain/Entities/DayStatusTests.swift` exists

**Workout Duration Migration:**
- Files:
  - `HealthTracker/Domain/Entities/Workout.swift` (lines 55-90)
  - `HealthTracker/Data/Migration/DataMigration.swift`
- Why fragile: Dual decoding paths (old int format vs new struct format); edge cases with raw values >= 7
- Safe modification: Test thoroughly with both old and new data formats; never remove old format support without data analysis
- Test coverage: Migration has tests - `HealthTrackerTests/Data/DataMigrationTests.swift`

**Calendar Synchronization Logic:**
- Files: `HealthTracker/Presentation/Views/Components/CalendarStrip.swift` (lines 132-173)
- Why fragile: Race conditions between `isLoadingPast` flag, `needsMorePastDates` flag, and async date loading
- Safe modification: Always test rapid scrolling scenarios; consider state machine instead of boolean flags
- Test coverage: Missing - no unit tests for CalendarStrip

## Scaling Limits

**Analytics Date Range:**
- Current capacity: Loads all data in date range into memory
- Limit: Will become slow with 2+ years of daily data (730+ days)
- Scaling path: Implement pagination; pre-compute analytics at write time; use database with indexing

**JSON File Storage:**
- Current capacity: Single JSON file for all health data
- Limit: File I/O becomes slow at ~10MB (roughly 5-10 years of data with current schema)
- Scaling path: Migrate to SQLite or Core Data; implement date-based partitioning (one file per month)

**In-Memory Days Array:**
- Current capacity: MainViewModel keeps all loaded days in memory
- Limit: ~1000-2000 days before memory pressure (depends on meal/workout count per day)
- Scaling path: Lazy loading with pagination; only keep visible date range + buffer in memory

## Dependencies at Risk

**None identified:**
- Risk: Standard library and iOS SDK only (SwiftUI, Foundation, Charts)
- Impact: No third-party dependency risks
- Migration plan: Not applicable

## Missing Critical Features

**No Data Backup/Export:**
- Problem: Users cannot export their health data or create manual backups
- Blocks: User data portability; recovery from accidental deletions; data analysis in external tools
- Priority: Medium - iCloud provides automatic backup but no user control

**No Conflict Resolution for iCloud:**
- Problem: No handling for iCloud sync conflicts when same data modified on multiple devices
- Blocks: Reliable multi-device usage; last-write-wins may cause data loss
- Priority: High if app used on multiple devices

**No Offline Support Indicator:**
- Problem: No visual indication when app falls back to local storage (iCloud unavailable)
- Blocks: User awareness of sync status
- Priority: Medium - silent failures confuse users

**No Analytics Test Coverage:**
- Problem: CalculateAnalyticsUseCase (384 lines) has no corresponding test file
- Blocks: Safe refactoring; confidence in complex calculations
- Priority: High - core business logic should have comprehensive tests

## Test Coverage Gaps

**Missing Analytics Use Case Tests:**
- What's not tested: All analytics calculations (meals, water, workouts, mood, overall health scores)
- Files: `HealthTracker/Domain/UseCases/CalculateAnalyticsUseCase.swift`
- Risk: Silent calculation errors; regressions during refactoring
- Priority: High

**Missing AnalyticsViewModel Tests:**
- What's not tested: Period selection logic and analytics data loading
- Files: `HealthTracker/Presentation/ViewModels/AnalyticsViewModel.swift`
- Risk: UI state bugs; incorrect data displayed for selected periods
- Priority: Medium

**Missing Presentation Layer Tests:**
- What's not tested: All SwiftUI views and most view logic
- Files: All files under `HealthTracker/Presentation/Views/`
- Risk: UI regressions; broken user interactions
- Priority: Low - SwiftUI views are hard to unit test; consider UI testing instead

**Missing ICloudDriveDataSource Tests:**
- What's not tested: File coordination, fallback behavior, error handling
- Files: `HealthTracker/Data/DataSources/ICloudDriveDataSource.swift`
- Risk: Data loss on sync failures; incorrect fallback behavior
- Priority: High - core data persistence layer

**Missing Integration Tests:**
- What's not tested: End-to-end data flow from UI → ViewModel → UseCase → Repository → DataSource
- Files: N/A - no integration test suite exists
- Risk: Component integration bugs slip through unit tests
- Priority: Medium

---

*Concerns audit: 2026-02-26*
