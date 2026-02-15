# Feature Backlog — Focus Interval (MVP 1.2)

Centralized list of feature ideas. Keep entries in chronological order with
newest at the end.

Entry template:
ID:
Title:
Type:
Scope:
Priority:
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
