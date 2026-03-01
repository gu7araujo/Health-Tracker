# Phase 04 Plan Revision Summary

**Date:** 2026-03-01
**Mode:** Targeted updates to address checker issues

## Issues Addressed

### 1. Frontmatter Completeness (Blocker)
**Both Plans (04-01, 04-02)**

**Issue:** Missing required frontmatter fields: `phase`, `plan`, `type`, `must_haves`

**Fix Applied:**
- Added `phase: "04-testing-and-refinement"` to both plans
- Added `plan: "04-01"` and `plan: "04-02"` respectively
- Added `type: "auto"` for autonomous execution
- Added `must_haves` as YAML array with truth-verification pairs

### 2. Task Structure (Blocker)
**Both Plans (04-01, 04-02)**

**Issue:** Plans used markdown sections (`### Task N:`) instead of required XML `<task>` elements

**Fix Applied:**
- Converted all markdown task sections to XML structure:
  ```xml
  <task>
  <files>path/to/file</files>
  <action>detailed instructions</action>
  <verify>verification steps</verify>
  <done>completion criteria</done>
  </task>
  ```
- **04-01:** 3 tasks (Enhance ScheduleNotificationsUseCase tests, Complete CancelNotificationsUseCase tests, Add edge case tests)
- **04-02:** 6 tasks (Create UAT frontmatter, Document unit test verification, Document debug mode tests, Document permission flows, Document edge cases, Add summary/gaps)

### 3. Must-Haves Quality (Blocker)
**Plan 04-01**

**Issue:** Must-haves were test-focused ("60-notification scheduling validated") rather than system truths about user-observable outcomes

**Fix Applied:**
Replaced test-centric statements with system truths mapped to verification:

**Before:**
- "60-notification scheduling validated"
- "Date-specific identifiers validated"

**After:**
- truth: "Notifications schedule correctly for 30 days with unique date-specific identifiers"
  verification: "ScheduleNotificationsUseCaseTests validates 60 notifications scheduled with lunch-reminder-YYYY-MM-DD and evening-reminder-YYYY-MM-DD patterns"
- truth: "Cancellation works for today's notifications only, preserving future days"
  verification: "CancelNotificationsUseCaseTests validates exactly 2 identifiers cancelled with today's date, using Date() for day boundary logic"
- truth: "Non-repeating notifications enable per-day cancellation without affecting future schedules"
  verification: "Tests validate repeats: false for all 60 notifications and full DateComponents (year, month, day, hour, minute) presence"
- truth: "Multiple cancellation calls handle rapid data entry without errors"
  verification: "Edge case tests demonstrate multiple execute() calls succeed, simulating logging meal then workout then water in succession"
- truth: "Authorization states correctly prevent or allow notification scheduling"
  verification: "Permission denial, notDetermined, provisional states have passing test coverage in ScheduleNotificationsUseCaseTests"

### 4. Requirement Coverage Clarity (Blocker)
**Plan 04-01**

**Issue:** NOTIF-20 coverage unclear - plan claimed to cover but didn't specify if MockNotificationService already exists or if new work needed

**Fix Applied:**
Updated Context section to clarify:

**Before:**
- "MockNotificationService already exists with comprehensive tracking - reuse, don't duplicate"

**After:**
- "MockNotificationService created in Phases 1-3 already satisfies NOTIF-20 requirement with comprehensive tracking - this plan enhances tests that USE the mock, not creating the mock itself"

**Clarification:** MockNotificationService was created during Phases 1-3 and already fully satisfies NOTIF-20. This phase enhances the tests that utilize the existing mock infrastructure, not the mock itself.

### 5. Must-Haves in 04-02
**Plan 04-02**

Applied same system-truth approach:
- truth: "All unit tests pass validating Use Case logic correctness"
  verification: "Test 1 in UAT confirms ScheduleNotificationsUseCaseTests (13 tests) and CancelNotificationsUseCaseTests (6 tests) all pass"
- truth: "Notifications fire at correct times in both debug and production builds"
  verification: "Tests 2-3 verify debug mode (2-3 min testable times) and release mode (1 PM, 8 PM) both work correctly"
- truth: "Permission flows handle grant and denial gracefully without crashes"
  verification: "Tests 4-5 confirm app continues functioning when user denies permission, and schedules correctly when granted"
- truth: "iOS edge cases handled correctly by calendar triggers and cancellation persistence"
  verification: "Tests 6-10 validate time zone changes, DST transitions, force quit persistence, rapid data entry, and delivered notification cleanup"
- truth: "Manual testing documentation provides clear pass/fail criteria"
  verification: "UAT.md contains objective criteria for each test case with concrete expected outcomes"

## Content Preserved

**No replanning from scratch** - all original task content, requirements, and implementation details remained intact:
- Task descriptions unchanged
- Test case details preserved
- Verification criteria maintained
- Notes sections kept
- Dependencies and wave structure preserved

## Files Modified

1. `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/.planning/phases/04-testing-and-refinement/04-01-PLAN.md`
   - Added frontmatter fields
   - Converted 3 tasks to XML structure
   - Replaced must_haves with system truths
   - Clarified NOTIF-20 coverage
   - Removed redundant "Must-Haves" markdown section

2. `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/.planning/phases/04-testing-and-refinement/04-02-PLAN.md`
   - Added frontmatter fields
   - Converted 6 tasks to XML structure
   - Replaced must_haves with system truths
   - Removed redundant "Must-Haves" markdown section

## Checker Compliance

All blocker issues resolved:
- ✅ task_completeness: XML task elements with <files>, <action>, <verify>, <done>
- ✅ task_completeness: Complete frontmatter with phase, plan, type, must_haves
- ✅ requirement_coverage: NOTIF-20 clarified (mock exists, plan enhances tests using it)
- ✅ verification_derivation: Must_haves reframed as system truths with verification mappings

## Autonomous Execution Ready

Both plans now executable by gsd-executor without interpretation:
- Clear file paths in <files> elements
- Actionable instructions in <action> elements
- Concrete verification steps in <verify> elements
- Observable completion criteria in <done> elements
- System truths in frontmatter must_haves guide goal-backward verification
