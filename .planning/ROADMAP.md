# Roadmap: HealthTracker Notifications

## Overview

This roadmap delivers iOS local notifications to remind users to log health data at two fixed times daily (1 PM and 8 PM). The journey progresses from architectural foundation (Phase 1) through basic scheduling (Phase 2), smart cancellation logic (Phase 3), to comprehensive testing (Phase 4). Each phase builds on the previous, following Clean Architecture principles and preventing common iOS notification pitfalls through protocol-based abstraction, calendar-based triggers, and intelligent cancellation when users log data.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Notification Service Foundation** - Establish Clean Architecture integration with permission handling
- [ ] **Phase 2: Basic Notification Scheduling** - Implement daily 1 PM and 8 PM notifications with time-aware messages
- [ ] **Phase 3: Smart Cancellation Logic** - Cancel notifications when user logs any data type
- [ ] **Phase 4: Testing and Refinement** - Comprehensive testing with edge case validation

## Phase Details

### Phase 1: Notification Service Foundation
**Goal**: App has notification permission and Clean Architecture foundation for notification features
**Depends on**: Nothing (first phase)
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-15, NOTIF-16, NOTIF-17, NOTIF-19
**Success Criteria** (what must be TRUE):
  1. App requests notification permission on first launch
  2. App gracefully handles permission denial without crashing
  3. NotificationServiceProtocol exists in Domain layer with no UserNotifications imports
  4. NotificationService implementation wraps UNUserNotificationCenter in Data layer
  5. ViewModels can use notification operations without importing UserNotifications framework
**Plans**: 3

Plans:
- [ ] 01-01: Create Domain layer protocol and types (Wave 1)
- [ ] 01-02: Implement Data layer service and Use Case (Wave 2)
- [ ] 01-03: Integrate permission request and add tests (Wave 3)

### Phase 2: Basic Notification Scheduling
**Goal**: Users receive daily notifications at 1 PM and 8 PM with time-specific messages
**Depends on**: Phase 1
**Requirements**: NOTIF-05, NOTIF-06, NOTIF-07, NOTIF-08, NOTIF-09, NOTIF-10, NOTIF-18, NOTIF-23
**Success Criteria** (what must be TRUE):
  1. User receives notification at 1:00 PM with message "Time to log your lunch!"
  2. User receives notification at 8:00 PM with message "How was your day? Log your health data"
  3. Notifications recur daily automatically without manual rescheduling
  4. Notifications fire at correct local time after time zone changes or DST transitions
  5. Debug configuration allows testable notification times for development
**Plans**: TBD

Plans:
- [ ] 02-01: TBD

### Phase 3: Smart Cancellation Logic
**Goal**: Notifications cancel intelligently when user logs any data, preventing notification fatigue
**Depends on**: Phase 2
**Requirements**: NOTIF-11, NOTIF-12, NOTIF-13, NOTIF-14
**Success Criteria** (what must be TRUE):
  1. User logs a meal and no further notifications fire that day
  2. User logs a workout and no further notifications fire that day
  3. User logs water intake and no further notifications fire that day
  4. User logs mood and no further notifications fire that day
  5. Cancellation works correctly even if user force-quits app immediately after logging
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

### Phase 4: Testing and Refinement
**Goal**: Notification system verified through comprehensive testing and edge case handling
**Depends on**: Phase 3
**Requirements**: NOTIF-20, NOTIF-21, NOTIF-22
**Success Criteria** (what must be TRUE):
  1. Unit tests pass for all Use Cases with mock NotificationService
  2. Manual device test plan confirms notifications fire at actual 1 PM and 8 PM
  3. Edge cases verified (rapid data entry, force quit, time zone changes, DST transitions)
  4. Debug logging provides visibility into notification scheduling and cancellation operations
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Notification Service Foundation | 0/3 | Ready to execute | - |
| 2. Basic Notification Scheduling | 0/TBD | Not started | - |
| 3. Smart Cancellation Logic | 0/TBD | Not started | - |
| 4. Testing and Refinement | 0/TBD | Not started | - |
