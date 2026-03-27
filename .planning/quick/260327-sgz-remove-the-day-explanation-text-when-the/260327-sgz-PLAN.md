---
phase: quick
plan: 260327-sgz
type: execute
wave: 1
depends_on: []
files_modified:
  - HealthTracker/Presentation/Views/MainView.swift
autonomous: true
requirements: []

must_haves:
  truths:
    - "When the day status is optimal (green), no explanation text is shown below the calendar strip"
    - "When the day status is moderate (yellow) or poor (red), the explanation text is still shown"
    - "When the day status is noData or incomplete, no explanation text is shown (unchanged behavior)"
  artifacts:
    - path: "HealthTracker/Presentation/Views/MainView.swift"
      provides: "Updated condition that excludes .optimal from showing the explanation"
  key_links:
    - from: "MainView.swift datePickerSection"
      to: "viewModel.currentDayStatus"
      via: "guard condition check"
      pattern: "currentDayStatus.*optimal"
---

<objective>
Hide the day explanation text when the day status is optimal (green). The text should only appear for moderate and poor statuses, not when everything is going well.

Purpose: Reduces visual noise on good days — there is nothing to explain when all health goals are met.
Output: Updated condition in MainView.swift's `datePickerSection` that excludes `.optimal`.
</objective>

<execution_context>
@/Users/gustavosantos/Documents/Projects/Personal/Real-app-repos/HealthTracker/.claude/get-shit-done/workflows/execute-plan.md
@/Users/gustavosantos/Documents/Projects/Personal/Real-app-repos/HealthTracker/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

Key facts:
- `DayStatus` cases: `.optimal` (green), `.moderate` (yellow), `.poor` (red), `.incomplete`, `.noData`
- The explanation text block lives in `MainView.swift` inside `datePickerSection` (around line 103)
- Current condition already excludes `.noData` and `.incomplete`; need to also exclude `.optimal`
- `viewModel.currentDayStatus` returns the status for the selected day
</context>

<tasks>

<task type="auto">
  <name>Task 1: Exclude .optimal from day explanation text condition</name>
  <files>HealthTracker/Presentation/Views/MainView.swift</files>
  <action>
In `datePickerSection`, locate the `if let explanation` block (around line 103). The current condition is:

```swift
if let explanation = viewModel.currentDayExplanation,
   viewModel.currentDayStatus != .noData,
   viewModel.currentDayStatus != .incomplete {
```

Add a third exclusion so the text only shows for `.moderate` and `.poor`:

```swift
if let explanation = viewModel.currentDayExplanation,
   viewModel.currentDayStatus != .noData,
   viewModel.currentDayStatus != .incomplete,
   viewModel.currentDayStatus != .optimal {
```

No other changes needed — the rest of the block (Text rendering, animation, padding) stays the same.

After editing, run swiftformat and swiftlint:
```bash
cd /Users/gustavosantos/Documents/Projects/Personal/Real-app-repos/HealthTracker && swiftformat HealthTracker/Presentation/Views/MainView.swift --swift-version 6 && swiftlint --fix HealthTracker/Presentation/Views/MainView.swift && swiftlint HealthTracker/Presentation/Views/MainView.swift
```
  </action>
  <verify>
    <automated>cd /Users/gustavosantos/Documents/Projects/Personal/Real-app-repos/HealthTracker && grep -n "currentDayStatus != .optimal" HealthTracker/Presentation/Views/MainView.swift</automated>
  </verify>
  <done>The condition includes `viewModel.currentDayStatus != .optimal`, confirmed by grep. Swiftlint and swiftformat pass with no errors.</done>
</task>

</tasks>

<verification>
- Grep confirms `.optimal` exclusion is present in the condition
- Build succeeds (use BuildProject via Xcode MCP or xcodebuild)
- When selectedDate has optimal status, no explanation text renders below the calendar strip
- When selectedDate has moderate or poor status, explanation text still renders
</verification>

<success_criteria>
Explanation text hidden for `.optimal` days, visible only for `.moderate` and `.poor` statuses.
</success_criteria>

<output>
After completion, create `.planning/quick/260327-sgz-remove-the-day-explanation-text-when-the/260327-sgz-SUMMARY.md`
</output>
