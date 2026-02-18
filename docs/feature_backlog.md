# Feature Backlog — Focus Interval (MVP 1.2)

Centralized list of feature ideas. Keep entries in chronological order with
newest at the end.

Entry template:
ID:
Title:
Type:
Scope: S | M | L (Small / Medium / Large)
Priority: P0 | P1 | P2 (Critical / High / Normal)
Status:

Problem / Goal:
Summary:

Design / UX:
Layout / placement:
Visual states:
Animation rules:
Interaction:
Text / typography:

Data & Logic:
Source of truth:
Calculations:
Sync / multi-device:

Edge cases:
Accessibility:
Dependencies:
Risks:
Acceptance criteria:
Notes:

---

## Recommended execution order (updated 18/02/2026)

This section defines the recommended implementation order. The idea entries
below remain in chronological order; new ideas must be appended at the end.
When a new idea is added, update this list to place it in the appropriate
execution slot.

1. IDEA-014 — Disable Task Weight When Only One Task Is Selected
2. IDEA-026 — Manage Presets Item UX Consistency
3. IDEA-015 — Live "Start Now" Time Ranges in Task List
4. IDEA-004 — Schedule Auto-Start Conditions Disclosure (Planning UX)
5. IDEA-017 — Start Time Picker Minimum Valid Time (Pre-Run Aware)
6. IDEA-007 — Time Until Scheduled Start (Plan Group + Groups Hub Summary)
7. IDEA-016 — Live Plan Group Preview + Real-Time Conflict Gating
8. IDEA-012 — Exact End Time Option for Scheduled Planning
9. IDEA-006 — Scheduled vs Actual End in Groups Hub Summary
10. IDEA-020 — Show "Scheduled By" in Group Summary
11. IDEA-029 — Live Pause Time Ranges (Forward-Only)
12. IDEA-018 — Live Pause Time Range Updates in Run Mode Task List
13. IDEA-005 — Pause Time Visibility (Run Mode + Groups Hub)
14. IDEA-013 — Global Group Remaining Time + Pending Tasks
15. IDEA-009 — Sticky "Go to Task List" CTA in Groups Hub
16. IDEA-008 — Collapsible Groups Hub Sections + Counts
17. IDEA-002 — Simplification of Status Boxes in Run Mode
18. IDEA-003 — Responsive Timer Scaling (Desktop/Web)
19. IDEA-010 — Ownership Request Explainer (Run Mode)
20. IDEA-011 — Mirror Notifications for Active Runs
21. IDEA-019 — Break Tasks List in Run Mode
22. IDEA-001 — Circular group progress ring around timer
23. IDEA-027 — Unified Mode Indicator + Session Context
24. IDEA-021 — Account Deletion Action in Settings
25. IDEA-022 — Verified Presence + Activity Heatmap
26. IDEA-028 — Verified Activity Summary + Week Start Setting
27. IDEA-023 — Resume Canceled Groups
28. IDEA-024 — Workspaces With Shared TaskRunGroups
29. IDEA-025 — Workspace Break Chat (Text + Deferred DM)

Notes:
- IDEA-028 depends on IDEA-022.
- IDEA-025 depends on IDEA-024.
- IDEA-029 and IDEA-018 overlap; keep both for now and merge later if needed.

## IDEA-001 — Circular group progress ring around timer

ID: IDEA-001
Title: Circular group progress ring around timer
Type: UI/UX
Scope: L
Priority: P1
Status: idea

Problem / Goal:
Replace the current linear group progress bar with a circular ring that wraps
the timer, making task segments and progress feel spatially aligned with the clock.

Summary:
A full ring surrounds the timer. Each task occupies a proportional angular
segment. A visual chip sits on each segment and reflects task state.

Design / UX:
Layout / placement:
Full ring around the timer (outer ring). Start point at 12:00 (top center).
Progress advances anti-clockwise, same direction as the timer.

Visual states:
Not started: chip outline uses the task color.
Running: chip outline uses the existing execution animation (same gradient and
motion as the current running progress bar).
Completed: chip outline turns gray regardless of task color.
Progress fill follows the existing specs: segments fill by task order; the
running task segment animates as it advances.

Animation rules:
Reuse the current running progress shader/animation. Transitions between
notStarted -> running -> completed are smooth and consistent with existing
progress animations.

Interaction:
Chips are tappable/clickable and open the task summary/detail (same behavior
as the current group progress bar). Updates live with activeSession changes.

Text / typography:
Task name text is centered within the curved chip area. Orientation rules:
If the segment is mostly in the upper half, text baseline faces the ring.
If mostly in the lower half, text baseline faces away from the ring.
Use ellipsis when the segment is too small; expose full name via tooltip and
accessibility labels.

Data & Logic:
Source of truth:
Use TaskRunGroup + activeSession only. No new authoritative state.

Calculations:
Angular span per task is proportional to task duration relative to the group
total (same as the linear bar spec). Progress sweeps anti-clockwise in order.

Sync / multi-device:
No change to ownership logic; presentation updates atomically from the same
session stream already in use.

Edge cases:
Single task uses full 360 degrees with centered text.
Tiny segments use fallback chip markers when text cannot fit; still render the
segment proportionally. If chips collide, reduce size or collapse to a compact
marker list accessible via interaction.
Responsive sizing must preserve legibility on small screens.

Accessibility:
All chip text rendered on canvas must be mirrored in Semantics labels with the
full task name and progress state.

Dependencies:
Timer screen progress widget and existing running animation shader.

Risks:
Text on curved segments, chip collisions on small screens, and performance if
too many segments are animated simultaneously.

Acceptance criteria:
Ring wraps the timer fully, start at 12:00, progress anti-clockwise.
Each task maps to a proportional segment; chips follow the same order.
Chip outlines reflect task state (color, running animation, gray on completion).
Progress fill advances segment-by-segment with correct colors and animation.
Text is centered and oriented for readability; ellipsis + tooltip when needed.
Chip interaction opens the same detail UI as the current bar.
Uses existing task durations and activeSession data; no logic changes.

Notes:
This is a visual-only change; all execution and sync rules remain unchanged.

---

## IDEA-002 — Simplification of status boxes in Run Mode (visual optimization inside the circle)

ID: IDEA-002
Title: Simplification of status boxes in Run Mode (visual optimization inside the circle)
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Reduce visual noise inside the timer circle while keeping state clarity and
consistent visual language.

Summary:
Simplify the Run Mode status chips by trimming text and using stroke thickness
to distinguish short vs long breaks, without changing state logic or colors.

Design / UX:
Layout / placement:
Keep the existing vertical order and placement of the two-line status chip
inside the circle.

Visual states:
Pomodoro: line 1 "Run X of Y"; line 2 time range (HH:mm–HH:mm); remove redundant
"Pomodoro running" text.
Break: line 1 "Break"; line 2 time range (HH:mm–HH:mm); remove "Short break" or
"Long break" labels.
Short vs long break: no text or icons; use chip border thickness (short = thin
stroke, long = thick stroke) following the thin/thick blue ring logic used in
Task List, break duration card, and interval dots.

Animation rules:
No change to existing animations; only text content and break border thickness
change.

Interaction:
No change to Run Mode interaction; chip behavior remains as currently defined.

Text / typography:
Keep current typography and text color (red for pomodoro, blue for break).
Keep dark chip background. Borders: red (#E53935) for pomodoro, blue (#1E88E5)
for breaks.

Data & Logic:
Source of truth:
Use existing Run Mode state (PomodoroMachine + PomodoroViewModel); no new
authoritative state.

Calculations:
Time range formatting and run counts remain unchanged. Break type selects the
stroke thickness only.

Sync / multi-device:
No change; presentation-only update.

Edge cases:
If break type is unavailable, default to short-break stroke thickness. Ensure
the thickness difference remains legible on small screens.

Accessibility:
Expose semantics that include break type (short/long) and time range even when
the visible text is simplified.

Dependencies:
Execution Screen status chip layout and shared thin/thick stroke tokens used in
existing UI elements.

Risks:
Stroke thickness contrast may be too subtle at small sizes; ensure minimum
visibility while preserving base colors.

Acceptance criteria:
Pomodoro chip shows "Run X of Y" + time range; no "Pomodoro running" text
appears.
Break chip shows "Break" + time range; no "Short/Long break" text appears.
Short vs long break is communicated solely by border thickness with the same
thin/thick logic as existing blue ring cues.
Chip background stays dark; text colors remain red/blue; borders use #E53935
(pomodoro) and #1E88E5 (break).
Vertical order, state logic, and base colors remain unchanged.

Notes:
Visual-only optimization for clarity and space inside the circle; no behavior
changes.

---

## IDEA-003 — Responsive Timer Scaling (Desktop/Web)

ID: IDEA-003
Title: Responsive Timer Scaling (Desktop/Web)
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Make the Run Mode timer scale proportionally on desktop/web so it looks elegant
in large windows while guaranteeing no overflow or layout instability.

Summary:
Introduce a dedicated Run Mode layout metrics layer that computes a clamped
scaleFactor from available width and scales the circle, text, spacing, ring
thickness, and markers proportionally. Mobile behavior remains unchanged.

Design / UX:
Layout / placement:
Apply scaling only on desktop/web (kIsWeb or macOS/Windows/Linux). Use
LayoutBuilder to derive availableWidth and keep the strict vertical order
inside the circle per specs.

Visual states:
No color or state logic changes. Pomodoro/break/Pre-Run visuals stay identical,
only sized by the scaleFactor.

Animation rules:
No changes to existing ring, marker, or progress animations; maintain 60fps
and avoid layout jumps during window resize.

Interaction:
No interaction changes; Run Mode controls and ownership behavior remain
unchanged.

Text / typography:
Scale the main countdown, current time, and status chip fonts proportionally
within min/max bounds to prevent overflow. Preserve tabular figures behavior
for the countdown.

Data & Logic:
Source of truth:
Pure presentation change. No new state; PomodoroViewModel remains unchanged.

Calculations:
Compute scaleFactor = clamp(availableWidth / baseDesignWidth, minScale,
maxScale). Base all sizes on the same metrics object to preserve proportions
and ensure internal content never exceeds the circle.

Sync / multi-device:
No change to sync, ownership, or session logic.

Edge cases:
Minimum window size, ultra-wide windows, and live resize must not cause text
overflow, chip clipping, or circle overrun. Verify Pre-Run, pomodoro, break,
paused, mirror, owner, and completion states.

Accessibility:
Ensure text remains legible at minScale and that semantics labels are unchanged.
Avoid truncating semantic content even if visual text is compacted.

Dependencies:
TimerScreen layout, TimerDisplay sizing inputs, group progress ring widget,
and a new Run Mode layout metrics class (e.g., RunModeLayoutMetrics).

Risks:
Over-scaling could cause cramped interior spacing or subtle animation jitter;
mitigate by lowering maxScale rather than adding layout hacks.

Acceptance criteria:
Desktop/web Run Mode scales smoothly with window size using a clamped
scaleFactor derived from availableWidth / baseDesignWidth.
Circle diameter, ring thickness, marker size, font sizes, and vertical
spacing scale proportionally without overflow or layout shifts.
Mobile behavior remains unchanged from current responsive logic.
No changes to ViewModel logic, state transitions, or sync behavior.
Run Mode remains stable across resize with 60fps animations.

Notes:
If scaling introduces instability, cap maxScale lower instead of forcing
complex conditional layouts.

---

## IDEA-004 — Schedule Auto-Start Conditions Disclosure (Planning UX)

ID: IDEA-004
Title: Schedule Auto-Start Conditions Disclosure (Planning UX)
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
Clarify when a scheduled TaskRunGroup actually starts in Account Mode so users
do not expect auto-start without any active device.

Summary:
Add a clear, reusable explanation in the planning flow that scheduled groups
start only when at least one device is open at or after the scheduled time. If
the time passes while all devices are closed, execution starts on next app open.

Design / UX:
Layout / placement:
In the planning screen, show the disclosure when a schedule option is selected
(start time / total range / total time). Provide an info icon near the Confirm
CTA that reopens the explanation at any time.

Visual states:
Use the existing planning info modal style. Keep Start now unaffected.

Animation rules:
None beyond existing modal transitions.

Interaction:
Modal appears the first time a schedule option is chosen, with "Don't show
again" saved per device. When opened via the info icon, omit the toggle and
show the same content for quick reference.

Text / typography:
Keep copy short and explicit. Emphasize: "A scheduled group starts when a
device is open at or after the planned time."

Data & Logic:
Source of truth:
Existing scheduling rules in specs section 10.4.1. No behavior changes.

Calculations:
None.

Sync / multi-device:
No change; this is a communication-only update.

Edge cases:
If the scheduled time passes while all devices are closed, the message must
state that the group starts on next app open. Ensure the disclosure is still
reachable later via the info icon.

Accessibility:
Modal content must be fully readable by screen readers. The info icon needs
an accessible label referencing scheduled start conditions.

Dependencies:
Planning screen info modal and per-device preference storage for "Don't show
again" (see specs 10.4.1).

Risks:
Overlong copy could be ignored; keep it concise and focused on the two key
conditions.

Acceptance criteria:
When a schedule option is selected, the user sees a clear disclosure about
the auto-start requirement (device open at or after scheduled time).
If all devices were closed at the scheduled time, the disclosure states the
group starts on next app open.
The same information is accessible via an info icon near Confirm.
No scheduling logic or ownership behavior changes.

Notes:
This is a UX-only clarification of existing business rules.

---

## IDEA-005 — Pause Time Visibility (Run Mode + Groups Hub)

ID: IDEA-005
Title: Pause Time Visibility (Run Mode + Groups Hub)
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Paused groups lack clear visibility of how long they have been paused and the
total paused time for the group, making timeline shifts feel arbitrary.

Summary:
Show a live "paused elapsed" timer in Run Mode while status == paused and
display the total accumulated paused time on the Groups Hub group item.

Design / UX:
Layout / placement:
Run Mode: surface a paused elapsed line (e.g., "Paused: 00:07:32") without
changing the strict vertical order inside the circle; place near the status
area or controls and only render while paused. Groups Hub: add a "Total paused"
row in the group card or summary area.

Visual states:
Paused only. Hide the indicator in running/pre-run/completed states.
Use existing paused visual language (neutral/amber) and avoid layout jumps
when the indicator appears.

Animation rules:
No new animations; the paused elapsed timer updates once per second.

Interaction:
None; purely informational.

Text / typography:
Use tabular digits for time. Keep labeling explicit ("Paused", "Total paused").

Data & Logic:
Source of truth:
Derived-only. Use activeSession.pausedAt for current paused elapsed and
TaskRunGroup theoreticalEndTime vs actualStartTime + totalDurationSeconds for
total paused time.

Calculations:
Paused elapsed = now - pausedAt (when status == paused).
Total paused = max(0, theoreticalEndTime - (actualStartTime + totalDurationSeconds)).

Sync / multi-device:
Mirror devices display the same values derived from the shared session/group.
Local Mode follows its existing pause-loss behavior on app close.

Edge cases:
If pausedAt is missing, hide the paused elapsed indicator.
In Local Mode, if the app was closed while paused, the paused elapsed resets
on reopen; keep messaging consistent with the existing pause warning.

Accessibility:
Expose the paused elapsed and total paused values in Semantics labels.

Dependencies:
Run Mode layout (TimerScreen) and Groups Hub group cards/summary layout.

Risks:
Additional text may crowd small layouts; ensure it does not break the circle
stack or card spacing.

Acceptance criteria:
When status == paused, Run Mode shows a live paused elapsed timer.
Groups Hub shows total paused time for each group.
No changes to scheduling or ownership logic; data is derived only.
Mirror devices show consistent values; Local Mode behaves per existing rules.

Notes:
UX-only visibility improvement for pause time; no business logic changes.

---

## IDEA-006 — Scheduled vs Actual End in Groups Hub Summary

ID: IDEA-006
Title: Scheduled vs Actual End in Groups Hub Summary
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
Group Summary shows only the real end time, so users cannot compare the
planned end versus the actual end when pauses shift the timeline.

Summary:
Add "Scheduled end" and "Actual end" to Group Summary. Hide Scheduled end
for non-planned runs (scheduledStartTime == null).

Design / UX:
Layout / placement:
Group Summary timing section should list Scheduled start, Actual start,
Scheduled end, Actual end in a clear order. Follow the existing timing layout
and formatting rules.

Visual states:
Only show Scheduled end when the group was scheduled. Actual end always shows
for completed/canceled groups when available.

Animation rules:
None.

Interaction:
None.

Text / typography:
Use existing summary typography and HH:mm formatting rules. Keep labels explicit
("Scheduled end", "Actual end").

Data & Logic:
Source of truth:
Scheduled end = TaskRunGroup.theoreticalEndTime (planned end).
Actual end = TaskRunGroup.end/finishedAt (real end after pauses).

Calculations:
No new calculations; only display existing values.

Sync / multi-device:
Presentation only; no sync changes.

Edge cases:
For non-planned runs, omit Scheduled start and Scheduled end.
If actual end is missing (running group), hide Actual end.

Accessibility:
Ensure timing labels are exposed in Semantics for screen readers.

Dependencies:
Groups Hub summary modal layout and date/time formatting utilities.

Risks:
More timing rows may increase scroll; keep the summary compact and readable.

Acceptance criteria:
Scheduled end appears in Group Summary for planned runs and matches the planned
theoreticalEndTime.
Actual end appears when the group has finished and reflects pause-adjusted end.
Non-planned runs do not show Scheduled end.

Notes:
Visibility-only change; no behavior or scheduling logic changes.

---

## IDEA-007 — Time Until Scheduled Start (Plan Group + Groups Hub Summary)

ID: IDEA-007
Title: Time Until Scheduled Start (Plan Group + Groups Hub Summary)
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Users see the scheduled start time but not how long remains until the group
begins, which makes temporal context unclear.

Summary:
Show a "Starts in" indicator in Plan group preview and a live countdown in the
Groups Hub summary modal for scheduled groups.

Design / UX:
Layout / placement:
Plan group preview: add a "Starts in" line near the Start/End timing fields
without replacing them. Groups Hub summary: add a "Starts in" row in the timing
section that updates while the modal is open.

Visual states:
Only for scheduled groups (scheduledStartTime != null). Hide when the group is
already running or scheduledStartTime <= now.

Animation rules:
No new animations; countdown updates at the same cadence used for other visible
timers (minutely or per-second, consistent with existing patterns).

Interaction:
None.

Text / typography:
Use clear, compact labels:
< 24h: "Starts in: HH h MM min"
>= 24h: "Starts in: DD d HH h MM min"

Data & Logic:
Source of truth:
scheduledStartTime + current device time (projection).

Calculations:
Remaining = max(0, scheduledStartTime - now). Format per rules above.

Sync / multi-device:
Presentation only; no changes to scheduling or ownership logic.

Edge cases:
If scheduledStartTime <= now, hide the "Starts in" line to avoid showing 0 min.
If the group is already running or completed, do not show the countdown.

Accessibility:
Expose the remaining time in Semantics for screen readers.

Dependencies:
Plan group preview layout and Groups Hub summary modal layout.

Risks:
Additional timing rows may increase vertical density; keep spacing consistent
with existing summary sections.

Acceptance criteria:
Plan group preview shows "Starts in" for scheduled groups with clear formatting.
Groups Hub summary shows a live countdown while the modal is open.
Non-planned runs do not show "Starts in"; no behavior changes.

Notes:
Visibility-only change; scheduling rules remain unchanged.

---

## IDEA-008 — Collapsible Groups Hub Sections + Counts

ID: IDEA-008
Title: Collapsible Groups Hub Sections + Counts
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Groups Hub becomes scroll-heavy as Scheduled/Completed/Canceled lists grow, and
users cannot see section totals at a glance.

Summary:
Collapse all non-active sections by default (Scheduled/Completed/Canceled/etc.),
show counts in section headers, and keep Running/Paused always expanded. Keep
Scheduled ordering from nearest to farthest start time.

Design / UX:
Layout / placement:
Use section headers as collapsible toggles with a chevron. Header text includes
the count, e.g., "Canceled (3)". Collapsed sections show only the header.

Visual states:
Running and Paused are always expanded. All other sections are collapsed on
initial entry but can be expanded/collapsed by the user.

Animation rules:
Optional simple expand/collapse animation; avoid layout jank on large lists.

Interaction:
Tap header to expand/collapse. The expanded state is local to the session unless
explicitly persisted per device (optional, not required).

Text / typography:
Keep existing section typography. Count uses the same style as header text.

Data & Logic:
Source of truth:
Existing Groups Hub sectioning and group status values.

Calculations:
Section count = number of groups in the section. Scheduled sorting is ascending
by scheduledStartTime (nearest first).

Sync / multi-device:
Presentation only; no changes to sync or status logic.

Edge cases:
Empty sections can be hidden or shown as "Section (0)" per current UI rules;
do not show expand controls for empty sections unless already standard.
If Scheduled has a mix of past-due and future items, still order by time.

Accessibility:
Section headers must be accessible buttons with count included in labels (e.g.,
"Canceled, 3 groups, collapsed").

Dependencies:
Groups Hub list/section renderer and header component.

Risks:
Users may miss collapsed content; ensure the chevron and counts are clear.

Acceptance criteria:
Running/Paused sections always visible and expanded.
All other sections are collapsed by default and can be toggled.
Section headers display total counts (e.g., "Completed (7)").
Scheduled section is ordered from nearest to farthest start time.
No business logic changes; presentation only.

Notes:
UX-only change to reduce scroll and improve at-a-glance context.

---

## IDEA-009 — Sticky "Go to Task List" CTA in Groups Hub

ID: IDEA-009
Title: Sticky "Go to Task List" CTA in Groups Hub
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
The "Go to Task List" CTA scrolls away in Groups Hub, forcing users to return
to the top when reviewing long histories.

Summary:
Pin the "Go to Task List" CTA to the top of Groups Hub, outside the scrollable
list, so it remains accessible at all times.

Design / UX:
Layout / placement:
Place the CTA in a fixed header area above the scrollable content. Keep the
current text/style and spacing. The group list scrolls independently below it.

Visual states:
Always visible in Groups Hub regardless of scroll position.

Animation rules:
None.

Interaction:
No changes to navigation behavior; same destination and action.

Text / typography:
Reuse existing CTA text and styling.

Data & Logic:
Source of truth:
None; presentation-only change.

Calculations:
None.

Sync / multi-device:
No impact.

Edge cases:
Ensure the CTA does not overlap the AppBar or insets on small screens. The
scrollable list should account for the fixed header height.

Accessibility:
CTA remains reachable via keyboard navigation and screen readers.

Dependencies:
Groups Hub layout structure (header + scrollable list).

Risks:
Reduced vertical space for the list on small screens; ensure content remains
usable without clipping.

Acceptance criteria:
The "Go to Task List" CTA remains visible at the top while scrolling.
The list scrolls independently below the fixed CTA.
No behavior changes to navigation; presentation only.

Notes:
UX-only placement change to reduce friction in long lists.

---

## IDEA-010 — Ownership Request Explainer (Run Mode)

ID: IDEA-010
Title: Ownership Request Explainer (Run Mode)
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Users do not understand what "Request ownership" does or how priority and
auto-claim work when the owner is stale, leading to confusion and false
expectations.

Summary:
Show a concise explainer when the user taps "Request ownership" and allow
re-opening it from the ownership UI. The explainer reflects current ownership
rules (active owner, stale owner, auto-claim priority, running vs paused).

Design / UX:
Layout / placement:
Show the explainer using a presentation pattern that is valid for the platform
(avoid stacking a modal on top of the ownership sheet if that violates UI
conventions). If a nested modal is not acceptable, use an in-sheet expand,
inline panel, or a full-screen info route. Include an "OK" action and an
optional "Don't show again" toggle saved per device. Provide an info affordance
in the ownership UI to reopen the explainer.

Visual states:
Shown only on mirror devices when requesting ownership. Use existing ownership
sheet visual language.

Animation rules:
Use existing modal transitions only.

Interaction:
If "Don't show again" is enabled, skip the auto-open next time but keep the
info affordance available.

Text / typography:
Use short, user-friendly bullets aligned to current rules:
- If the owner is active, your request stays pending until they approve/reject.
- If the owner is stale and the session is running, a mirror may auto-claim.
  If a request exists, the requester has priority; otherwise the first mirror
  to detect staleness claims ownership.
- If the session is paused, auto-claim only occurs when there is a pending
  request.

Data & Logic:
Source of truth:
Current ownership rules in specs (active vs stale owner, running vs paused).

Calculations:
None.

Sync / multi-device:
No changes to ownership logic; presentation only.

Edge cases:
If rules change in specs, update the explainer copy to match. If ownership data
is unavailable, show a generic explanation without state-specific claims.

Accessibility:
Explainer content must be readable by screen readers; info affordance labeled.

Dependencies:
Ownership sheet UI and per-device preference storage.

Risks:
Outdated copy if rules change without updating the explainer.

Acceptance criteria:
Tapping "Request ownership" shows the explainer with OK (and optional "Don't
show again"). The same information is accessible later via the ownership UI.
Copy matches current active/stale and running/paused rules.

Notes:
Communication-only feature; no ownership behavior changes.

---

## IDEA-011 — Mirror Notifications for Active Runs

ID: IDEA-011
Title: Mirror Notifications for Active Runs
Type: UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Execution notifications (pomodoro end, group end, etc.) are currently emitted
from owner-side callbacks only, so mirror devices with the app open miss key
progress signals.

Summary:
Deliver the same execution notifications to mirror devices while the group is
running/paused and the app is open. No new notification types.

Design / UX:
Layout / placement:
Reuse the existing local/system notification pattern. Trigger on mirror devices
when Run Mode is visible or the app is active.

Visual states:
Mirror and owner look identical for execution notifications when the app is
open. No changes to colors or sounds beyond current behavior.

Animation rules:
Follow existing notification animation rules.

Interaction:
No new actions; notifications remain informational only.

Text / typography:
Use existing notification copy and styling.

Data & Logic:
Source of truth:
ActiveSession phase transitions (mirror projection), aligned to the same event
boundaries as the owner-side PomodoroMachine callbacks.

Calculations:
None; reuse existing timing triggers.

Sync / multi-device:
Mirror devices should mirror notifications when the app is open. This is
presentation-only and must not change ownership or session state.

Edge cases:
Do not deliver notifications on mirror devices when the app is closed.
Avoid duplicate notifications when switching owner/mirror roles mid-run.
If a device is offline, do not attempt to queue notifications for later.

Accessibility:
Ensure notifications remain accessible with screen readers.

Dependencies:
Notification service, Run Mode session listeners, ownership state handling.

Risks:
Potential duplicate notifications on rapid owner changes; ensure role switch
de-duplicates within a short time window.

Acceptance criteria:
When a group is running or paused and the app is open, owner and mirror devices
receive the same execution notifications.
No change to notification types or ownership logic.
Closed apps do not receive additional notifications beyond current behavior.

Notes:
Scope is UX parity for open-app devices; does not alter background notification
policy.

---

## IDEA-012 — Exact End Time Option for Scheduled Planning

ID: IDEA-012
Title: Exact End Time Option for Scheduled Planning
Type: UI/UX
Scope: L
Priority: P1
Status: idea

Problem / Goal:
Users cannot force an exact end time when scheduling by total range or total
time because pomodoros/breaks are fixed and pomodoros are integer-only.

Summary:
Add an "Exact end time" switch in Plan group that allows a controlled exception
to the integer pomodoro rule so the final end time matches the user’s target.

Design / UX:
Layout / placement:
Add a switch labeled "Exact end time" in the planning options area for
Schedule by total range time and Schedule by total time. Include an info icon
that reopens a short explainer.

Visual states:
When enabled, preview and time ranges reflect the exact end. When disabled,
use current behavior with adjusted end notice.

Animation rules:
None beyond existing planning transitions.

Interaction:
On first enable, show an explainer modal with "Don't show again" (per-device).
Subsequent access via the info icon.

Text / typography:
Keep copy explicit: only the final segment may be shortened to hit the exact
end time.

Data & Logic:
Source of truth:
Planning flow for Schedule by total range time / Schedule by total time.
Store an explicit flag on the TaskRunGroup snapshot (e.g., exactEndTimeEnabled)
to keep preview and execution aligned.

Calculations:
If the exact end falls inside the last pomodoro, shorten that final pomodoro.
If the exact end falls inside the last break:
- Short break: convert the final break into final work time until the exact end.
- Long break: convert to a short break, then final work time until the exact end.
Only the final segment is adjusted; the rest of the group remains standard.

Sync / multi-device:
No new sync rules, but execution must follow the stored exact-end flag so owner
and mirrors render the same final timing.

Edge cases:
If the exact end already matches a segment boundary, no adjustment occurs.
If the exact end is before start, block scheduling with a clear warning.
Do not apply the exception when "Exact end time" is off.

Accessibility:
Explainer and switch must be screen-reader friendly with clear labels.

Dependencies:
Plan group preview, scheduling redistribution logic, Run Mode time-range
projection, and group summary timing.

Risks:
Users may misinterpret the exception; copy must be explicit and consistent.

Acceptance criteria:
With "Exact end time" on, the group ends exactly at the target time in both
preview and execution.
Only the final segment may be shortened/converted; all other pomodoros/breaks
remain unchanged.
With the switch off, current behavior (integer pomodoros + adjusted end notice)
remains unchanged.

Notes:
This feature intentionally introduces a controlled exception to current rules;
the UI must make the exception clear.

---

## IDEA-013 — Global Group Remaining Time + Pending Tasks

ID: IDEA-013
Title: Global Group Remaining Time + Pending Tasks
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Users only see the current phase timer; there is no clear, consistent view of
overall remaining group time, especially for running/paused/canceled states.

Summary:
Expose a global “group remaining time” in Group Summary (and optionally near the
group progress ring), with state-specific behavior, plus a list of unfinished
tasks for canceled groups.

Design / UX:
Layout / placement:
Group Summary: add a “Group remaining” row in the timing section. If approved,
also show a subtle secondary label near the group progress ring (outside the
main phase timer) to avoid competing with the phase countdown.

Visual states:
Running: live countdown updates while the modal is open.
Paused: remaining time is frozen while paused.
Canceled: show the remaining time at the moment of cancellation.

Animation rules:
Reuse existing countdown update cadence (per-second or per-minute) without new
animations.

Interaction:
None.

Text / typography:
Use secondary styling (e.g., muted gray) so the phase timer remains primary.

Data & Logic:
Source of truth:
Derive remaining time from TaskRunGroup actualStartTime/theoreticalEndTime and
pause offsets. Use activeSession for live projection when running.

Calculations:
Remaining = max(0, theoreticalEndTime - now) for running.
Paused: Remaining is fixed to the value at pause time.
Canceled: Remaining is fixed to the value at cancellation time.

Sync / multi-device:
Derived-only; mirrors use the same activeSession/group data for projection.

Edge cases:
If end time is missing, hide the remaining label.
If the group is completed, do not show remaining time.

Accessibility:
Expose the remaining time and pending task list in Semantics labels.

Dependencies:
Groups Hub summary modal, group progress ring layout, and task completion
tracking for canceled groups.

Risks:
Additional timing labels may clutter the UI; ensure hierarchy stays clear.

Acceptance criteria:
Group Summary shows a global remaining time for running/paused/canceled groups.
Running counts down, paused stays fixed, canceled shows the last remaining value.
Canceled groups list the unfinished tasks in order.
No changes to execution or scheduling logic.

Notes:
Visibility-only enhancement to preserve context during execution and review.

---

## IDEA-014 — Disable Task Weight When Only One Task Is Selected

ID: IDEA-014
Title: Disable Task Weight When Only One Task Is Selected
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
When only one task is selected for a group, Task weight (%) is always 100% and
editing it has no effect, which can confuse users.

Summary:
If exactly one task is selected in group preparation and the user edits that
task, show Task weight as fixed 100% and disable the control.

Design / UX:
Layout / placement:
Keep the Task weight field visible but disabled with value 100%. Add a short
helper note such as "Only one task selected" if space allows.

Visual states:
Disabled state only when a single task is selected. In 2+ task selections, the
field behaves normally (editable).

Animation rules:
None.

Interaction:
Disabled field does not accept input. No additional actions.

Text / typography:
Use existing Task weight labeling and formatting.

Data & Logic:
Source of truth:
Group selection context in Plan group / Task Editor.

Calculations:
None; value is fixed to 100% when only one task is selected.

Sync / multi-device:
No impact.

Edge cases:
If selection changes from 1 to 2+ tasks while editor is open, re-enable the
field and restore normal behavior.

Accessibility:
Expose disabled state and reason to screen readers.

Dependencies:
Task Editor UI and selection-scoped Task weight logic.

Risks:
None; small UI-only change.

Acceptance criteria:
With exactly one selected task, Task weight shows 100% and is disabled.
With 2+ selected tasks, Task weight is editable as currently defined.
No changes to redistribution logic beyond UI enable/disable.

Notes:
UX-only clarification aligned to selection-scoped weight rules.

---

## IDEA-015 — Live "Start Now" Time Ranges in Task List

ID: IDEA-015
Title: Live "Start Now" Time Ranges in Task List
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
Time range chips in Task List are only recalculated on interaction, so they
become stale if the user waits before starting the group.

Summary:
Auto-refresh the Start now time range chips for selected tasks so the preview
always reflects the current time without extra user actions.

Design / UX:
Layout / placement:
Keep the current chip layout and visuals. Update only the displayed time values.

Visual states:
Time ranges update while the Task List is open and tasks are selected.

Animation rules:
No new animations; time values refresh at a steady cadence (e.g., every minute).

Interaction:
None.

Text / typography:
Use existing time range formatting (HH:mm–HH:mm).

Data & Logic:
Source of truth:
Current time + existing duration/ordering rules for Start now preview.

Calculations:
Recompute start/end ranges at a fixed interval using the same logic as current
selection/reorder updates.

Sync / multi-device:
Local UI only; no sync changes.

Edge cases:
If no tasks are selected, do not run refresh timers. If the app is backgrounded,
pause updates and refresh on resume.

Accessibility:
Ensure updated time values are reflected in Semantics labels.

Dependencies:
Task List selection preview renderer and timing calculation helper.

Risks:
Unnecessary rebuilds; keep refresh cadence minimal to avoid performance issues.

Acceptance criteria:
When tasks are selected, time range chips stay aligned with the current time.
Ranges update automatically without requiring selection changes or reorder.
No changes to scheduling or duration logic.

Notes:
Presentation-only refresh to keep Start now previews accurate.

---

## IDEA-016 — Live Plan Group Preview + Real-Time Conflict Gating

ID: IDEA-016
Title: Live Plan Group Preview + Real-Time Conflict Gating
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Plan group previews (Start/End and task time ranges) can become stale while the
screen is open, and conflicts may appear over time without blocking Confirm.

Summary:
Keep Start now previews in sync with “now”. For Schedule modes, keep the
preview fixed to the chosen plan unless the scheduled start becomes stale
(pre-run window or start time passes), in which case rebase the preview to the
current time (next valid start) using the selected schedule mode, re-check
conflicts, and warn that the start time was updated. This keeps the displayed
start time confirmable (pre-run window in the future). The pre-run window must
always be reserved and must never overlap other groups.

Design / UX:
Layout / placement:
Reuse existing preview layout and conflict messaging. Add a clear inline warning
when a conflict is detected and disable Confirm.

Visual states:
Start now: Start/End and task ranges update automatically each minute.
Schedule: Preview stays coherent with the selected plan. If the scheduled start
or pre-run window is now in the past, rebase the preview to "now" using the
same schedule mode rules (total range or total time), preserving the full
pre-run window, update Start/End and task ranges, and show a clear warning.

Animation rules:
No new animations; time values refresh at a steady cadence.

Interaction:
Confirm becomes disabled when a conflict is detected; re-enables once resolved.

Text / typography:
Use existing time formatting (HH:mm–HH:mm). Conflict warning copy should be
short and consistent with current overlap messaging.

Data & Logic:
Source of truth:
Existing planning preview calculations and conflict/overlap rules.

Calculations:
Recompute preview Start/End and task ranges at a fixed cadence (e.g., per minute).
For Schedule modes, only rebase when the planned start/pre-run window becomes
stale; otherwise keep the fixed schedule. Rebased schedules must ensure the
pre-run window fits in the future and does not overlap existing groups.

Sync / multi-device:
Local UI only; no sync changes.

Edge cases:
If no tasks are selected, avoid refresh timers. If the app is backgrounded,
pause updates and refresh on resume. Ensure partial updates never occur; all
preview fields must update together. If the pre-run window start time has
already passed, automatically rebase the schedule to the nearest valid start
(now + noticeMinutes) with a warning so Confirm does not fail due to stale
timing. If the rebased schedule still conflicts with other groups, keep Confirm
disabled until the user resolves the conflict.

Accessibility:
Conflict warnings must be announced by screen readers. Disabled Confirm should
have an accessible reason.

Dependencies:
Plan group preview renderer, scheduling conflict checks, and Confirm CTA state.

Risks:
Increased rebuilds; keep cadence minimal and avoid heavy recomputation.

Acceptance criteria:
Plan group preview Start/End and task ranges stay aligned with current time in
Start now mode.
Schedule previews remain fixed unless the planned start/pre-run window becomes
stale; then the preview rebases to now using the same schedule mode rules,
reserving the full pre-run window and showing a warning that the start time was
auto-updated to stay valid.
Confirm is disabled immediately when an overlap appears, and re-enabled when
resolved, with a clear warning. Confirm should not fail due to stale timing
once the preview has rebased.
No changes to business rules; presentation and gating only.

Notes:
UX-only improvement to keep previews accurate and prevent late conflicts.

---

## IDEA-017 — Start Time Picker Minimum Valid Time (Pre-Run Aware)

ID: IDEA-017
Title: Start Time Picker Minimum Valid Time (Pre-Run Aware)
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
Users can select a start time that is already invalid because the pre-run
window would begin in the past, leading to late error messages.

Summary:
Make the start-time picker default and constraints respect the minimum valid
time based on now + noticeMinutes (pre-run), so invalid times are avoided up
front and auto-adjusted with a clear warning if time passes.

Design / UX:
Layout / placement:
In Schedule by total range time / total time, initialize the picker to the
earliest valid start time. If the user tries to pick earlier, clamp to the
minimum and show a brief notice.

Visual states:
Only applies in Schedule modes (not Start now). If the picker becomes stale
while open, auto-shift to the new minimum and warn.

Animation rules:
None.

Interaction:
If an auto-adjust occurs (time now invalid), show a lightweight message like
"Start time updated to allow pre-run".

Text / typography:
Use existing planning warning style and copy patterns.

Data & Logic:
Source of truth:
Current time + noticeMinutes pre-run requirement.

Calculations:
Minimum valid start = now + noticeMinutes (+ optional UX buffer if already used
elsewhere). The full pre-run window must be reservable.

Sync / multi-device:
No impact.

Edge cases:
If noticeMinutes == 0, minimum valid start is now (plus optional buffer).
If the minimum valid time crosses midnight/day boundaries, ensure the picker
updates the date as needed.

Accessibility:
Auto-adjust warnings must be announced to screen readers.

Dependencies:
Planning start-time picker and pre-run validation helpers.

Risks:
Users may be surprised by auto-adjust; keep the warning clear and brief.

Acceptance criteria:
Start-time picker opens at a valid time that preserves the full pre-run window.
Invalid past times are prevented or clamped with a clear warning.
Schedule modes only; no change to business rules.

Notes:
UX-only guardrail aligned to existing pre-run reservation rules.

---

## IDEA-018 — Live Pause Time Range Updates in Run Mode Task List

ID: IDEA-018
Title: Live Pause Time Range Updates in Run Mode Task List
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
When a group is paused, task time ranges under the timer stay frozen until
resume, drifting from the status boxes and the real paused timeline.

Summary:
While paused, keep task list time ranges updating in real time (minute cadence)
so they reflect the accumulating pause offset and remain consistent with the
status boxes.

Design / UX:
Layout / placement:
No layout changes; update the existing time range chips under the timer.

Visual states:
Paused: time ranges continue to shift forward as pause time accumulates.
Running: unchanged behavior.

Animation rules:
No new animations; reuse the existing timer tick cadence.

Interaction:
None.

Text / typography:
Keep existing HH:mm–HH:mm formatting and styles.

Data & Logic:
Source of truth:
Use the same pause-offset projection used by the status boxes.

Calculations:
Recompute projected task ranges while paused at a fixed cadence (e.g., per
minute) and update the entire list together to avoid partial drift.

Sync / multi-device:
UI-only projection; no sync or ownership changes.

Edge cases:
Pause during pomodoro or break must behave the same. If the app is backgrounded,
pause updates and refresh on resume. Avoid excessive rebuilds when the list is
off-screen.

Accessibility:
Time range updates should not spam announcements; keep them silent.

Dependencies:
TimerScreen task list range renderer and pause-offset projection helpers.

Risks:
Extra rebuilds during long pauses; keep cadence minimal.

Acceptance criteria:
While paused, task list time ranges update in real time and match the status
box ranges. No changes to business rules or pause logic.

Notes:
Consistency fix for pause offsets in Run Mode UI.

---

## IDEA-019 — Break Tasks List in Run Mode

ID: IDEA-019
Title: Break Tasks List in Run Mode
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Run Mode lacks a lightweight place to capture and prioritize small tasks meant
for breaks, forcing users to leave the app or carry mental load during focus.

Summary:
Add a lightweight "Break tasks" list accessible from TimerScreen, with editing
and reordering, and restrict completion to break phases only. Persist locally
per device and per signed-in user. Default is device-only visibility, with an
optional share flow to copy the list to selected active devices that accept it.
Optional per-group scoping remains available.

Design / UX:
Layout / placement:
Add a discreet access point from TimerScreen (e.g., a corner affordance outside
the timer circle) that opens a compact list UI.

Visual states:
Pomodoro: list view allowed; completion controls disabled or hidden to avoid
encouraging break-task execution during focus time.
Break (short/long): completion controls enabled. If there are pending break
tasks, surface the next-in-order item as a small chip/label near the access
icon (or just below it) for quick review.

Animation rules:
None beyond existing list transitions.

Interaction:
Add, edit, delete items. Drag to reorder. Tap to expand long text. Long press
opens edit/delete actions. During breaks, tapping the surfaced "next" chip
opens a quick modal asking if the task is done (Yes / Not yet). Yes marks it
complete; Not yet keeps it in place. The chip is hidden during pomodoros.
Sharing: allow sharing the full list or selected items to chosen active devices.

Text / typography:
One-line default display; expand to show full text. Keep list visuals aligned
with existing Task List styling.

Data & Logic:
Source of truth:
Local persistence keyed by device + signed-in user. By default, lists are
visible only on the device that created them. Optional share flow can copy the
list to other devices (recipient must accept). No impact on TaskRunGroup.

Calculations:
None.

Sync / multi-device:
No background sync. Optional user-initiated sharing to active devices only.
Recipients accept or decline; accepted items are merged locally. Sharing can be
the full list or a selected subset of items.

Edge cases:
If no user is signed in, store under local scope. If switching accounts, swap
the list accordingly. If per-group mode is enabled, bind to groupId and keep a
separate default global list. Shared lists must dedupe by item id to avoid
duplicates; each break task must have a stable id.

Accessibility:
Ensure completion toggle is announced as disabled during pomodoro. Support
screen reader actions for reorder and edit/delete.

Dependencies:
TimerScreen overlay/sheet pattern, local storage (SharedPreferences in MVP),
Settings screen entry for managing the list, optional device discovery list
for active devices during sharing.

Risks:
UI clutter in TimerScreen; keep the entry minimal and optional.

Acceptance criteria:
Users can add/edit/reorder break tasks from Run Mode. Completion is only
available during break phases. During breaks, the next pending task is surfaced
as a chip/label and can be completed via a Yes/Not yet modal. Items persist per
device and per user and are visible only on the creating device by default.
Optional share allows copying the full list or selected items to chosen active
devices after they accept, with id-based dedupe. A Settings entry allows
managing the same list outside Run Mode.

Notes:
UX-only enhancement; no changes to TaskRunGroup scheduling or execution logic.

---

## IDEA-020 — Show "Scheduled By" in Group Summary

ID: IDEA-020
Title: Show "Scheduled By" in Group Summary
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
Group Summary lacks visibility into which device initiated schedule or Start
now, making multi-device history harder to reconstruct.

Summary:
Expose `scheduledByDeviceId` in Group Summary as a "Scheduled by" (or "Planned
by") field, with a clear legacy fallback when the field is missing.

Design / UX:
Layout / placement:
Add a single row in Group Summary near other timing metadata (Scheduled start,
Actual start, End).

Visual states:
If `scheduledByDeviceId` exists, show a device label. If not, show
"Unknown (legacy group)" or equivalent.

Animation rules:
None.

Interaction:
None.

Text / typography:
Use existing summary row styling. Prefer a human-readable device name if
available; otherwise show a short id token.

Data & Logic:
Source of truth:
TaskRunGroup.scheduledByDeviceId.

Calculations:
Resolve device id to a label using the existing device registry (if available);
fallback to a truncated id or "Unknown (legacy group)" when missing.

Sync / multi-device:
Read-only; no sync changes.

Edge cases:
Legacy groups without scheduledByDeviceId should display the fallback label
instead of hiding the row.

Accessibility:
Ensure the row is readable by screen readers with a clear label.

Dependencies:
Group Summary modal layout and device-label lookup (if present).

Risks:
Device ids may be opaque; ensure fallback labeling is clear and non-confusing.

Acceptance criteria:
Group Summary shows a "Scheduled by" row based on scheduledByDeviceId. Legacy
groups show "Unknown (legacy group)" (or equivalent). No business rules change.

Notes:
Visibility-only change for multi-device traceability.

---

## IDEA-021 — Account Deletion Action in Settings

ID: IDEA-021
Title: Account Deletion Action in Settings
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
Account Mode users cannot delete their account from within the app, creating
uncertainty about data removal and long-term access.

Summary:
Add an explicit "Delete account" action in Settings when authenticated in
Account Mode, with a clear destructive confirmation flow and a safe final
state (signed out, data access removed).

Design / UX:
Layout / placement:
Settings > Account section, visible only when Account Mode is active and the
user is signed in. Hide in Local Mode and on platforms without Account Mode.

Visual states:
Destructive styling (red or warning icon) with a strong confirmation dialog.

Animation rules:
None beyond existing modal transitions.

Interaction:
Tap shows a confirmation modal with explicit consequences. Require a deliberate
confirmation step (e.g., typed "DELETE" or double-confirm) before proceeding.

Text / typography:
Copy must clearly state that deletion is irreversible and clarifies data scope
and access loss. Use consistent warning copy patterns from other destructive
flows.

Data & Logic:
Source of truth:
Auth provider account deletion + server-side data deletion policy (as defined
in specs / backend rules).

Calculations:
None.

Sync / multi-device:
If deletion succeeds, sign out locally and clear Account Mode state. Other
devices should detect the auth change and return to signed-out state.

Edge cases:
If deletion fails (network/auth), show an error and keep the user signed in.
If the account has pending sessions, ensure they are ended or made inaccessible
per existing logout semantics. Legacy Local Mode data remains untouched.

Accessibility:
Confirmation dialog must be fully accessible and clearly labeled as destructive.

Dependencies:
Settings > Account UI, auth deletion capability, data cleanup policy,
platform-specific account providers.

Risks:
Destructive action requires precise copy and handling to avoid accidental loss.

Acceptance criteria:
Account Mode users see a "Delete account" action in Settings. The flow requires
explicit confirmation and results in a signed-out, consistent state on success.
Local Mode is unaffected. No changes to business rules beyond visibility and
safe deletion flow.

Notes:
Requires alignment with backend data-retention policy and auth provider rules.

---

## IDEA-022 — Verified Presence + Activity Heatmap

ID: IDEA-022
Title: Verified Presence + Activity Heatmap
Type: UI/UX
Scope: L
Priority: P1
Status: idea

Problem / Goal:
There is no way to confirm the user was present during each pomodoro and no
visual history of real, verified activity by day.

Summary:
Add a lightweight presence confirmation at the end of each pomodoro and use
only verified pomodoros to power a GitHub-style activity heatmap in the user
profile (personal vs workspace).

Design / UX:
Layout / placement:
Run Mode: show a small, non-blocking confirmation banner/toast near the bottom
of the timer at each pomodoro end. Profile/Settings: add a compact heatmap panel
near the user identity metadata.

Visual states:
Confirmation banner shows a single "Confirm" action. If not confirmed before
the next pomodoro starts, show a brief notice that the previous pomodoro will
not be counted.
Heatmap uses 5 intensity levels; empty days show a neutral tile.

Animation rules:
Use existing toast/banner transitions only.

Interaction:
User taps Confirm to verify the pomodoro. If ignored, the banner auto-dismisses
when the next pomodoro begins and marks the prior pomodoro unverified.

Text / typography:
Keep copy short and clear (e.g., "Confirm presence for the last pomodoro").
Use existing warning copy style for the "not counted" notice.

Data & Logic:
Source of truth:
Verified pomodoro events derived from TaskRunGroup execution, tagged with
timestamp, duration, workspaceId (if any), and deviceId of the confirmer.

Calculations:
Verified minutes per day = sum of confirmed pomodoro work minutes for that day.
Heatmap intensity levels map verified minutes to 5 buckets (e.g., ~1h minimum
to ~8h maximum), with thresholds defined in specs.

Sync / multi-device:
Confirmation should be owner-only to avoid conflicting writes; mirrors display
the result. If the app is not active when the banner would show, mark the
pomodoro unverified and surface the "not counted" notice on resume.

Edge cases:
If a group is paused at the pomodoro boundary, defer the banner until the
transition resumes. If the group is canceled or ends before confirmation, the
last pomodoro remains unverified. Offline confirmations should queue locally
and sync when online. Legacy groups without verification data show empty days.

Accessibility:
Banner and notices must be announced once via screen readers. Avoid repeated
announcements on rapid transitions.

Dependencies:
Run Mode banner/toast component, verified-pomodoro storage, daily aggregation,
profile/Settings UI for heatmap, workspace attribution source.

Risks:
User annoyance if prompts are too frequent; keep them minimal and consistent.
Additional storage and aggregation complexity; ensure retention policy is clear.

Acceptance criteria:
Each pomodoro end triggers a presence confirmation banner. Verified pomodoros
count toward the heatmap; unverified ones do not. Heatmap displays 7-row weekly
grid with 5 intensity levels, and supports personal vs workspace views. No
changes to TaskRunGroup execution logic.

Notes:
No manual time entry; activity is based on executed, verified pomodoros only.

---

## IDEA-023 — Resume Canceled Groups

ID: IDEA-023
Title: Resume Canceled Groups
Type: Product / UX
Scope: L
Priority: P1
Status: idea

Problem / Goal:
Canceled groups can only be re-planned from scratch, which forces users to lose
partial progress when they cancel due to interruptions.

Summary:
Add a Resume action for canceled groups that continues from the exact
cancellation point, while keeping Re-plan as the "start over" option. Update
cancel-confirmation copy to reflect both paths.

Design / UX:
Layout / placement:
Groups Hub: show both actions for canceled groups — Resume and Re-plan group.
Run Mode cancel confirmation modal: update copy to remove "cannot be resumed".

Visual states:
Canceled group card shows Resume as a primary/secondary action (per existing
CTA hierarchy) and Re-plan as the alternative.

Animation rules:
None.

Interaction:
Resume opens the group in Run Mode at the saved execution point. Re-plan opens
the planning flow as it does today.

Text / typography:
Cancel confirmation copy must explicitly state the two options available after
canceling (Resume vs Re-plan).

Data & Logic:
Source of truth:
TaskRunGroup execution snapshot at the time of cancel (current task index,
phase, remaining time offsets).

Calculations:
Resume must preserve completed segments and continue from the saved point
without restarting earlier tasks or pomodoros.

Sync / multi-device:
Resume follows existing ownership rules; only the owner can resume.

Edge cases:
If the group was canceled while paused, resume should restore paused state or
resume into a consistent running state per existing pause semantics.
If local data needed to resume is missing, fall back to Re-plan.

Accessibility:
Actions must be clearly labeled; cancellation dialog copy must be announced.

Dependencies:
Run Mode cancel flow copy, Groups Hub action menu, persisted execution snapshot
fields needed to resume, and any resume guards in the ViewModel.

Risks:
Conflicts with current spec rule "canceled groups cannot be resumed"; requires
spec update and careful backward compatibility. Resume logic could diverge from
completion/cancel timelines if snapshot fields are incomplete.

Acceptance criteria:
Canceled groups show Resume and Re-plan actions in Groups Hub. Resume continues
from the cancellation point with completed segments preserved. Cancel modal copy
no longer claims the group cannot be resumed and explains the two paths.

Notes:
This is a behavior change; specs must be updated before implementation.

---

## IDEA-024 — Workspaces With Shared TaskRunGroups

ID: IDEA-024
Title: Workspaces With Shared TaskRunGroups
Type: Product / Architecture
Scope: L
Priority: P1
Status: idea

Problem / Goal:
There is no shared workspace layer for planning and executing groups together,
and no clear rules for sharing groups across members with ownership and overlap
resolution.

Summary:
Introduce Workspaces where members can share existing TaskRunGroups from Groups
Hub, plan and execute them together, and resolve conflicts with personal groups.
Shared groups are copies of personal groups and do not sync changes back.
Shared groups do not carry a start time on share; the workspace owner sets the
exact start time later, so multiple shared groups can coexist before scheduling.

Design / UX:
Layout / placement:
Add a Workspaces entry with Create/Join flows. Provide a Workspace board that
lists shared groups and their run status. Sharing a group is done from Groups
Hub (any status: running, paused, scheduled, completed, canceled).

Visual states:
Workspace run mirrors the existing Run Mode UI for members. Members see the same
timer run across their devices. Workspace groups show planned/running state and
exclusion status when a member opts out due to overlap.

Animation rules:
Reuse existing run animations; no new visual effects required.

Interaction:
Members can propose/share a group from Groups Hub. Workspace owner can schedule
and start shared groups, including assigning the start time. Members must
resolve conflicts between workspace runs and their personal groups by either
opting out of the workspace run or modifying their personal group.
Optional setting: the workspace owner can allow automatic run ownership for any
member (no approval). When enabled, a member can take ownership immediately to
set start times if the owner/delegate is unavailable.

Text / typography:
Clear ownership and conflict copy. Explicitly state when a workspace group
cannot be edited by non-owners and when a member is excluded from a run.

Data & Logic:
Source of truth:
Workspace collections in Firestore plus a copied TaskRunGroup snapshot.

Calculations:
Overlap detection uses the same [start, end) intersection rules, including
pre-run windows when applicable. Conflicts are only evaluated once the owner
assigns a start time; shared groups can coexist without conflicts while
unscheduled. Exclusions prevent members from joining a workspace run that
conflicts with their personal groups.

Sync / multi-device:
Members see the same workspace run on all their logged-in devices. The workspace
run is a single shared session (not per device).

Edge cases:
If the workspace owner is offline when a run starts, ownership falls to the
designated delegate; if none, the first device to open at run start becomes run
owner. If a member does not resolve a conflict, auto-start is blocked for them
and they are excluded from that workspace run.
If auto-ownership is enabled, ensure only one member becomes owner at a time
and update the owner assignment before scheduling.

Accessibility:
Conflict decisions and exclusion states must be announced clearly. Workspace
ownership and run state should be readable via screen readers.

Dependencies:
Workspace data model, invite flow, workspace board UI, shared run ownership
rules, conflict-resolution UI that integrates with personal group overlaps.

Risks:
Large scope with new backend collections and ownership rules. Requires careful
spec alignment and release safety for new Firestore paths and rules.

Acceptance criteria:
Users can create/join workspaces and share any existing Groups Hub TaskRunGroup.
Shared groups are copied and independent of the original. Workspace runs are
visible to all members across devices. Shared groups have no start time until
the owner schedules them. Personal vs workspace overlap requires a forced
decision (opt out or modify personal group) once a start time is assigned, with
gating on unresolved conflicts.

Notes:
Workspace groups are shared from Groups Hub only; no new group creation inside
the workspace. This is a documentation-level feature proposal pending full
spec alignment.

---

## IDEA-025 — Workspace Break Chat (Text + Deferred DM)

ID: IDEA-025
Title: Workspace Break Chat (Text + Deferred DM)
Type: Product / UX
Scope: L
Priority: P1
Status: idea

Problem / Goal:
Workspace runs have no built-in communication channel for breaks, forcing
members to use external apps and reducing the social value of shared runs.

Summary:
Add a text-only workspace group chat for all members, plus direct messages (DM)
between members, both tied to the active workspace run and designed for breaks.
During pomodoros the chat is hidden or read-only. Direct messages are queued
during pomodoro and delivered at the next break. Chat sync must be data-efficient
by loading recent messages once and then only incremental updates.

Design / UX:
Layout / placement:
Workspace run view shows a compact chat panel or entry point visible during
breaks. Outside runs, provide a Workspace chat entry (and member DM list) so
messages can be reviewed and sent anytime. Profile/Settings provides a per-user
mute toggle for workspace chat.

Visual states:
Pomodoro: chat hidden or read-only; inbound messages are not delivered or
shown (to protect focus). Messages sent during pomodoro are queued.
Break: chat input enabled; queued messages become visible and deliver.
Muted: chat panel remains hidden and does not surface new messages.
Out of run: chat and DMs are accessible for reading and sending.

Animation rules:
Reuse existing panel transitions only.

Interaction:
Group chat (workspace-wide): members can read and post during breaks. Messages
show author and time in arrival order.
Direct chat (member-to-member DM): users can draft at any time, but delivery to
the recipient occurs only when the next break starts (queued -> delivered).
During pomodoro, users may draft/send, but incoming messages are not delivered
or notified until the next break. "Receive" means the messages become visible.

Text / typography:
Keep messages minimal and readable; show author and timestamp for context.

Data & Logic:
Source of truth:
Workspace run chat messages stored under the workspace run context, plus DM
threads between workspace members.

Calculations:
Queued DM delivery triggers on transition to shortBreakRunning or longBreakRunning.

Sync / multi-device:
Chat is visible on all devices for the same member account. Delivery gating is
based on the run phase, not device focus.

Edge cases:
If no run is active, chat remains accessible from the workspace hub (not the
Run Mode view). If a member is excluded from the run due to overlap, they do not
receive run chat. If a break starts while offline, queued DMs should deliver on
next reconnect at break.

Accessibility:
Chat visibility changes must be announced once. Provide accessible labels for
message author and time.

Dependencies:
Requires Workspaces with shared TaskRunGroups (IDEA-024). Needs a chat UI panel,
message storage, and run-phase gating.

Risks:
Chat could distract during focus if gating is weak. Data usage could grow without
incremental sync and caching.

Acceptance criteria:
Text chat is available during breaks for workspace runs and hidden or read-only
during pomodoros. DMs are queued during pomodoro and delivered at the next break.
Users can mute chat. Chat loads recent messages once and then only new messages
without re-downloading already seen history. No audio chat in this scope.

Notes:
Audio room is a future idea only and is not part of this scope.

---

## IDEA-026 — Manage Presets Item UX Consistency

ID: IDEA-026
Title: Manage Presets Item UX Consistency
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
Manage Presets list items do not follow the same interaction and preview
patterns as other lists, causing inconsistent UX for editing and deleting
presets.

Summary:
Align Manage Presets item layout and gestures with Task List patterns: preview
chips, default-star placement on the right, and consistent tap/long-press
behavior (tap = edit, long-press = select for delete).

Design / UX:
Layout / placement:
Preset item shows a preview row using the same visual language as Task List
chips/cards, but without total pomodoros. Show pomodoro minutes, short break,
long break, and long-break interval. Default star appears on the far right.

Visual states:
Default preset shows a visible star on the right. Selection state appears only
after long-press (not on tap).

Animation rules:
None beyond existing list interactions.

Interaction:
Short tap opens the preset editor. Long press enters selection mode for delete.
Deletion happens via the existing delete action after selection.

Text / typography:
Use existing list typography and preview styling; keep preset preview compact.

Data & Logic:
Source of truth:
Preset data in Settings / Manage Presets.

Calculations:
None.

Sync / multi-device:
No sync changes.

Edge cases:
If only one preset exists and it is default, star still appears on the right.
Selection mode must not trigger on short tap.

Accessibility:
Long-press action should be discoverable (e.g., via context menu) and announced.

Dependencies:
Manage Presets list item widget and selection/delete flow.

Risks:
Changing gesture behavior may surprise users; keep consistent with Task List.

Acceptance criteria:
Preset item preview matches Task List visual language (minus total pomodoros).
Default star is on the right. Tap opens editor. Long-press selects for delete.

Notes:
UX consistency change only; no changes to preset data or logic.

---

## IDEA-027 — Unified Mode Indicator + Session Context

ID: IDEA-027
Title: Unified Mode Indicator + Session Context
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
The Local/Account mode indicator and session context (current account + logout)
are inconsistent across screens, creating visual clutter and confusion about
the current session.

Summary:
Standardize the mode indicator placement across key screens, and centralize
session context and logout inside a single mode sheet to keep AppBars clean.

Design / UX:
Layout / placement:
Show the mode indicator consistently on the second AppBar line, left-aligned,
under the screen title. Apply to Task List, Settings, Groups Hub, Login, and
any other screen that currently shows the indicator.

Visual states:
Mode icon reflects Local vs Account. Login screen shows "No active session"
when logged out. Account mode shows current user identity and provider.

Animation rules:
None beyond existing sheet transitions.

Interaction:
Tapping the mode indicator opens a sheet that always shows:
Current mode (Local/Account), account identity if logged in, and actions
relevant to the mode (e.g., logout). The sheet is the single entry point for
session context across screens.

Text / typography:
Use consistent labels and avoid extra AppBar text like "your tasks" + logout
blocks. Keep the AppBar title clean.

Data & Logic:
Source of truth:
Current auth state and mode settings.

Calculations:
None.

Sync / multi-device:
No sync changes.

Edge cases:
Login screen must not show logout. If no active session exists, show a clear
state in the sheet without adding new flows. Respect platform availability
(Linux has Local Mode only).

Accessibility:
Mode sheet and labels must be readable by screen readers; ensure focus order.

Dependencies:
AppBar layout on Task List, Settings, Groups Hub, Login; mode sheet UI.

Risks:
Changing AppBar layout could affect visual balance; ensure consistent spacing.

Acceptance criteria:
Mode indicator appears in a fixed AppBar position across key screens. Tapping
it always shows the mode sheet with session context. Logout is removed from
Task List AppBar and is available via Settings and/or the mode sheet. AppBars
remain visually clean and consistent.

Notes:
UX-only standardization; no changes to auth logic.

---

## IDEA-028 — Verified Activity Summary + Week Start Setting

ID: IDEA-028
Title: Verified Activity Summary + Week Start Setting
Type: UI/UX
Scope: M
Priority: P1
Status: idea

Problem / Goal:
The activity heatmap (IDEA-022) lacks clear weekly/monthly totals and a task
breakdown, and there is no explicit week-start setting to define "this week."

Summary:
Add verified activity totals for the current week and month, plus a task-based
breakdown, with Personal vs Workspace separation. Add a "Week starts on"
setting (default from locale) that drives weekly grouping.

Design / UX:
Layout / placement:
Profile/Activity area: show "Verified time" totals for Week and Month, and a
task breakdown list/chart under each scope (Personal, Workspace).
Settings: add a "Week starts on" selector.

Visual states:
Week/Month totals show 0 when no verified time exists. Task breakdown is sorted
by highest verified time. Personal and Workspace views mirror heatmap tabs.

Animation rules:
None.

Interaction:
Switch between Personal and Workspace scopes. Week-start setting updates
week-based totals and groupings.

Text / typography:
Use clear labels like "This week" and "This month" tied to the configured
week-start. Keep task breakdown labels consistent with task/group naming.

Data & Logic:
Source of truth:
Verified pomodoros from IDEA-022 only (executed + confirmed).

Calculations:
Week total = verified minutes from the current week window (per week-start).
Month total = verified minutes from day 1 to today. Task breakdown aggregates
verified minutes by task (or task group if that is the visible entity).

Sync / multi-device:
No new sync rules; follows verified activity data.

Edge cases:
Locale-based default week start must be used until user overrides it. If tasks
were deleted/renamed, show the best available label for historical entries.

Accessibility:
Totals and breakdown lists must be screen-reader friendly and announce scope.

Dependencies:
Requires IDEA-022 data, profile/heatmap UI, Settings storage for week-start.

Risks:
Aggregation cost if computed on the fly; consider caching daily totals.

Acceptance criteria:
Profile shows verified totals for week and month, plus a task breakdown, with
Personal/Workspace separation. Week start can be set in Settings and affects
weekly grouping. Only verified pomodoros are counted.

Notes:
No manual time entry; aligns strictly with IDEA-022 verification rules.

---

## IDEA-029 — Live Pause Time Ranges (Forward-Only)

ID: IDEA-029
Title: Live Pause Time Ranges (Forward-Only)
Type: UI/UX
Scope: S
Priority: P1
Status: idea

Problem / Goal:
While a group is paused, task and status-box time ranges stay frozen, so the UI
does not reflect the accumulating pause offset in real time.

Summary:
Update all displayed time ranges in Run Mode during pauses so they reflect the
current pause offset, adjusting only forward in time (never rewriting past
starts or ends).

Design / UX:
Layout / placement:
No layout changes. Applies to task items below the timer and the status boxes.

Visual states:
Paused: ranges update in real time (e.g., per minute) to reflect delay.
Running: unchanged.

Animation rules:
No new animations; reuse existing timer tick cadence.

Interaction:
None.

Text / typography:
Keep HH:mm–HH:mm formatting.

Data & Logic:
Source of truth:
Pause-offset projection already used for time-range calculations.

Calculations:
If a range start is in the past, keep it fixed. Extend the current range end
by the pause offset, and shift all future ranges forward by the same offset.

Sync / multi-device:
UI-only projection; no sync changes.

Edge cases:
Applies to both task items and status boxes. Must update even if the user never
resumes. If the app is backgrounded, pause updates and refresh on resume.

Accessibility:
Avoid noisy announcements; time range updates should be silent.

Dependencies:
Run Mode time-range renderer for task items and status boxes.

Risks:
Extra rebuilds during long pauses; keep cadence minimal.

Acceptance criteria:
While paused, all displayed ranges update in real time, preserving past starts and ends
and shifting only forward. Task items and status boxes stay consistent.

Notes:
Consistency fix for pause offsets during paused state.
