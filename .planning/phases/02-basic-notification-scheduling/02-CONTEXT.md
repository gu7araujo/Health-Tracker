# Phase 2: Basic Notification Scheduling - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Schedule and deliver daily recurring notifications at 1 PM and 8 PM with time-specific messages in Portuguese-BR. Handle time zones and DST automatically. Include debug configuration for testing.

This phase focuses on the scheduling mechanism and notification delivery. User interaction with notifications (tapping to open specific screens) is a separate phase.

</domain>

<decisions>
## Implementation Decisions

### Notification Content (Portuguese-BR)
- **1 PM notification:** "Registre o que você comeu hoje" (action-focused, covers meals that may not be logged yet)
- **8 PM notification:** "Registre suas refeições e atividades" (comprehensive reminder for end-of-day logging)
- Notifications should use CFBundleDisplayName from project configuration as the title, with fallback to "HealthTracker"
- Content is action-oriented and acknowledges user may not have logged data yet

### Notification Presentation
- Use default system behavior: sound + badge + banner
- Respect user's system notification preferences
- Follow iOS best practices for permission and presentation
- Badge count handling: system default

### Claude's Discretion
- Scheduling implementation approach (recurring request vs multiple days, rescheduling strategy)
- Debug configuration design (how to enable testable times for development)
- Time zone and DST handling implementation (automatic adjustment mechanism)
- Notification identifiers and category structure
- Integration with existing NotificationService from Phase 1
- Error handling for scheduling failures
- Badge count management strategy

</decisions>

<specifics>
## Specific Ideas

- Portuguese-BR is the app language
- Notifications should acknowledge that users might not have logged meals yet (not assuming they already logged breakfast when 1 PM notification fires)
- 1 PM message is flexible enough to work whether user logged breakfast or not
- 8 PM message is comprehensive, covering meals and activities

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-basic-notification-scheduling*
*Context gathered: 2026-02-28*
