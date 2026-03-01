# Phase 04 Plan Revision Summary

**Date:** 2026-03-01
**Mode:** Targeted fixes for checker issues
**Plans Updated:** 04-01-PLAN.md, 04-02-PLAN.md

## Changes Made

### 04-01-PLAN.md (Enhance Use Case Unit Tests)

**Task Completeness (Blocker)**
- Added `<name>` element to Task 1: "Enhance ScheduleNotificationsUseCase Wave 0 Tests"
- Added `<name>` element to Task 2: "Complete CancelNotificationsUseCase Tests"
- Added `<name>` element to Task 3: "Add Edge Case Tests"

**Verification Derivation (Blocker)**
- Restructured `must_haves` from non-standard `truth/verification` format to standard format:
  - `truths`: Array of 5 truth statements about notification scheduling and cancellation
  - `artifacts`: 2 test files with path/provides/min_lines structure
  - `key_links`: 4 wiring relationships between tests, mocks, and Use Cases

**Key Links (Blocker)**
- Added 4 key_links showing:
  - ScheduleNotificationsUseCaseTests → MockNotificationService
  - CancelNotificationsUseCaseTests → MockNotificationService
  - ScheduleNotificationsUseCaseTests → ScheduleNotificationsUseCase
  - CancelNotificationsUseCaseTests → CancelNotificationsUseCase

### 04-02-PLAN.md (Create Manual Device Test Plan)

**Task Completeness (Blocker)**
- Added `<name>` element to Task 1: "Create 04-UAT.md with Frontmatter"
- Added `<name>` element to Task 2: "Document Unit Test Verification"
- Added `<name>` element to Task 3: "Document Debug Mode Notification Tests"
- Added `<name>` element to Task 4: "Document Permission Flow Tests"
- Added `<name>` element to Task 5: "Document iOS Edge Case Tests"
- Added `<name>` element to Task 6: "Add Summary and Gaps Sections"

**Verification Derivation (Blocker)**
- Restructured `must_haves` from non-standard `truth/verification` format to standard format:
  - `truths`: Array of 5 truth statements about manual testing coverage
  - `artifacts`: 1 UAT file with path/provides/min_lines structure
  - `key_links`: 4 wiring relationships between UAT tests and implementation files

**Key Links (Blocker)**
- Added 4 key_links showing:
  - UAT Test 1 → ScheduleNotificationsUseCaseTests
  - UAT Test 1 → CancelNotificationsUseCaseTests
  - UAT Tests 2-3 → ScheduleNotificationsUseCase (device testing)
  - UAT Tests 6-10 → CancelNotificationsUseCase (edge case testing)

**Scope Sanity (Warning)**
- Acknowledged: 6 tasks in 04-02 exceeds 4-task threshold
- Rationale: All tasks modify same file (04-UAT.md), logical document construction sequence
- Decision: Accept as-is, no split needed

## What Changed vs What Stayed the Same

### Changed
- Frontmatter `must_haves` structure (both plans): Non-standard format → Standard format
- Task headers (all tasks in both plans): Added `<name>` element after `<task>` opening tag
- Verification approach: Implicit verification → Explicit artifacts and key_links

### Stayed the Same
- Task content and instructions (no changes to `<action>`, `<verify>`, `<done>`)
- Plan goals and context (unchanged)
- Task sequencing and dependencies (unchanged)
- File modification lists (unchanged)
- All requirements (NOTIF-20, NOTIF-21, NOTIF-22 unchanged)
- Test case definitions in 04-02 (10 UAT tests unchanged)

## Issue Resolution Status

### Resolved (All Blockers)
- ✅ 04-01 Task Completeness: All 3 tasks now have `<name>` element
- ✅ 04-02 Task Completeness: All 6 tasks now have `<name>` element
- ✅ 04-01 Verification Derivation: must_haves restructured to standard format
- ✅ 04-02 Verification Derivation: must_haves restructured to standard format
- ✅ 04-01 Key Links: 4 key_links added showing test→mock and test→UseCase wiring
- ✅ 04-02 Key Links: 4 key_links added showing UAT→test files and UAT→implementation wiring

### Acknowledged (Warnings)
- ⚠️ 04-02 Scope Sanity: 6 tasks accepted as-is (all modify same file, logical sequence)

## Verification

Plans now conform to GSD planner standards:
- Standard must_haves structure (truths, artifacts, key_links)
- All tasks have descriptive names
- Clear wiring between test files and implementation
- Artifacts specify min_lines for scope validation

Ready for checker re-validation and executor assignment.
